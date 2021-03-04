# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper
include RallyEIF::WRK

describe "The JIRA Connector Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
    @connection = nil
    @rc = nil
    @connector = nil
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @connection = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @connection.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
  end

  after(:each) do
    @connection.disconnect() if !@connection.nil?
    @rc.disconnect() if !@rc.nil?
  end

  it "should copy a new issue from Jira to Rally" do
    #@jira.register_field_handler(JiraHTMLFieldHandler.new('Description'))
    issue, key = create_jira_issue({'Summary' => "frazzlebean stew" }, default_external_id=true)
    @connector.copy_to_rally({:artifact => issue})
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Name").should ==  @jira.get_value(issue, "Summary")
    @rc.get_value(rally_defect, "State").should == "Submitted"
  end

  it "should copy a new defect from Rally to JIRA" do
    fields = {
        :Name => "Chadron State newbies",
        :Priority => "Normal",
        :State => "Fixed",
    }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    @connector.copy_to_other({:artifact => rally_defect})
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Summary.should  == @rc.get_value(rally_defect, "Name")
    jira_bug.Status.should   == 'In Review'
    jira_bug.RallyURL.should == "#{@rc.detail_url}/defect/#{rally_oid}"
  end

  it "should copy a new Bug from Jira to Rally Defect, then update Jira after Rally Defect updated" do
    # create a Bug in Jira
    issue, key = create_jira_issue({'Summary' => "Lemon Meringue pie"})
    # copy Bug to Rally defect
    @connector.copy_to_rally({:artifact => issue})
    last_connector_run = Time.now.utc
    # find defect in Rally and verify rally_defect.name = summary and state = 'Submitted'
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Name").should  == issue.Summary
    @rc.get_value(rally_defect, "State").should == "Submitted"

    @rc.update(rally_defect, { :Priority => "Resolve Immediately",
                               :State    => "Fixed"
    })
    rally_defect = @rc.find_by_external_id(key)

    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    issue = @jira.find(key)
    issue.Status.should   == "In Review"
    issue.Priority.should == "Highest"
  end

  it "should copy a new Bug from Jira to Rally Defect, then use UPDATE_RALLYFIELDS_AND_OTHER service." do
    # create a Bug in Jira
    issue, key = create_jira_issue({'Summary' => "Apple pie", "Severity" => "Minor Problem"})
    # copy Bug to Rally defect
    @connector.copy_to_rally({:artifact => issue})
    # find defect in Rally and verify rally_defect.name = summary and state = 'Submitted'
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Name").should  == issue.Summary
    @rc.get_value(rally_defect, "State").should == "Submitted"
    last_connector_run = Time.now.utc
    sleep(1)

    # update the Rally defect Priority to Resolve Immediately, should map to Blocker in Jira
    @rc.update(rally_defect, { :Name     => "Rhubarb Pie",
                               :Priority => "Resolve Immediately"
    })
    rally_defect = @rc.find_by_external_id(key)
    @jira.update(issue, { :Severity => "Cosmetic"} )

    @connector.update_other_fields({:artifact => rally_defect, :last_run => last_connector_run})
    issue = @jira.find(key)
    issue.Summary.should  == "Rhubarb Pie"
    issue.Priority.should == "Highest"
    issue.Severity.should == "Cosmetic"    # should not be Minor.

    @connector.update_rally({:artifact => issue})
    rally_defect.refresh
    rally_defect.Severity.should == "None"
  end

  it "should copy a new defect from Rally to Jira Bug, then update Rally after Jira Bug updated" do
    # create a defect in Rally
    fields = {'Name'       => "Alamogordo Bright Flashes",
              'Priority'   => "Normal",
              'State'      => "Submitted"}
    rally_defect = @rc.create(fields)
    rally_oid    = @rc.get_value(rally_defect, "ObjectID")
    # copy Rally defect to Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})

    jira_bug = @connection.find_by_external_id(rally_oid)
    @connection.get_value(jira_bug, "Priority").should == 'Medium'
    @connection.get_value(jira_bug, "Status").should   == 'To Do'

    #@connection.update(jira_bug, {'Status' => "Done", 'Priority' => "Low", 'Resolution' => "Won't Do"})
    @connection.update(jira_bug, {'Status' => "Done", 'Priority' => "Low"})
    updated_bug = @connection.find_by_external_id(rally_oid)
    @connector.update_rally({:artifact=>updated_bug})

    rally_defect = @rc.find_by_external_id(jira_bug.key)
    @rc.get_value(rally_defect, 'State').should    == "Closed"
    @rc.get_value(rally_defect, 'Priority').should == "Low"
  end

  it "should create a defect in Rally with no priority set and copy to a Jira Bug (when no Priority mapped in config.xml)" do
    fms = @connector.field_mapping.reject { |map| map.rally_attr == :Priority }
    @connector.field_mapping = fms # drop the Priority mapping

    # create a defect in Rally
    fields = {'Name'       => "White Sands Rangers",
              'State'      => "Submitted"}
    rally_defect = @rc.create(fields)
    # copy Rally defect to Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})
    # find defect in Jira
    jira_bug = @jira.find_by_external_id(rally_defect.ObjectID)
    jira_bug.Priority.should == "Medium"
  end

  it "should create a Bug in Jira with no priority set and copy to a Rally defect" do
    fms = @connector.field_mapping.reject { |map| map.rally_attr == :Priority }
    @connector.field_mapping = fms # drop the Priority mapping

    fields = {}
    fields['Project']  = "TST"
    fields['Summary']  = "Experiment with Bug with no Priority mapping"
    fields['Assignee'] = @connection.user
    fields['Reporter'] = "devuser"
    oid = 54321 + rand(1000)
    fields[@connection.external_id_field()] = oid.to_s
    jira_bug = @connection.create(fields)
    # copy Jira Bug to Rally defect
    @connector.copy_to_rally({:artifact => jira_bug})
    rally_defect = @rc.find_by_external_id(jira_bug.key)
    rally_defect.Priority.should == "None"
  end

  it "should raise StandardError on attempt to copy Rally defect to Jira if defect has an unmapped user" do
    # create a defect in Rally and copy it to a Jira Bug

    fields = {
        'Name' => "Ypsilanti Yowlers",
        'Priority' => "Normal",
        'State' => "Submitted",
        'SubmittedBy' => @rc.user_by_username('test_user2@rallydev.com')
    }
    rally_defect = @rc.create(fields)
    warning = "Rally SubmittedBy value of |test_user2@rallydev.com| not mapped to a valid JIRA user field value. Skipping update of a user field"
    of = YetiTestUtils::OutputFile.new("rallylog.log")
    @connector.copy_to_other({:artifact => rally_defect})
    of.readlines.grep(/WARN.*#{warning}/).should_not be_empty
  end

  it "copy Rally defect to Jira and set a mapped user as Reporter" do
    # create a defect in Rally and copy it to a Jira Bug
    fields = {
        'Name' => "Ypsilanti Yowlers reported by this very insistant Yeti",
        'Priority' => "Normal",
        'State' => "Submitted",
        'Owner' => @rc.user_by_username('yeti@rallydev.com')
    }
    rally_defect = @rc.create(fields)
    jira_bug = @connector.copy_to_other({:artifact => rally_defect})
    jira_bug.Assignee.should == 'yeti'
  end

  it "should fail if crosslink field name does not exist for RallyConnection" do
    of = YetiTestUtils::OutputFile.new("rallylog.log")

    config = JiraSpecHelper::JIRA_CONFIG_FILE.gsub(/<CrosslinkUrlField>JiraLink<\/CrosslinkUrlField>/, "<CrosslinkUrlField>BuffaloChips</CrosslinkUrlField>")
    @konfab = Konfabulator.new(config)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @connection = RallyEIF::WRK::JiraRestConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @connection.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
    @connector.validate.should == false

    of.readlines.grep(/ERROR.* Rally CrosslinkUrlField name of \"BuffaloChips\" is not a valid field name/).should_not be_empty
  end

  it "should fail if crosslink field name does not exist for JiraConnection" do
    of = YetiTestUtils::OutputFile.new("rallylog.log")

    config  = JiraSpecHelper::JIRA_CONFIG_FILE.gsub(/<CrosslinkUrlField>RallyURL<\/CrosslinkUrlField>/, "<CrosslinkUrlField>BuffaloChips</CrosslinkUrlField>")
    @konfab = Konfabulator.new(config)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@root, @rc, @jira)
    @connector.validate.should == false

    of.readlines.grep(/ERROR.*JIRA CrosslinkUrlField name of \"BuffaloChips\" is not a valid field name/).should_not be_empty
  end

  it "should copy a new UserStory to JIRA and correctly set the CrosslinkUrlField" do
    of = YetiTestUtils::OutputFile.new("rallylog.log")

    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
    @connector.validate.should == true

    # create a UserStory in Rally
    fields = { :Name          => "Chattanooga ChooChooz",
               :ScheduleState => "Defined"
             }
    rally_story = @rc.create(fields)
    rally_oid   = @rc.get_value(rally_story, "ObjectID")
    # copy Rally story to Jira issue
    @connector.copy_to_other({:artifact => rally_story})

    # check that the RallyUrl field in the newly created JIRA issue is correct
    jira_issue = @jira.find_by_external_id(rally_oid)
    #rally_link = jira_issue.RallyUrl
    jira_issue.RallyURL.should == "#{@rc.detail_url}/userstory/#{rally_oid}"

    of.readlines.grep(/Rally CrossLinkUrlField name of \"JiraLink\" validated/).should_not be_empty
    of.readlines.grep(/JIRA CrossLinkUrlField name of \"RallyURL\" validated/).should_not be_empty
  end

  it "should update a Jira Issues Assignee when the assignee is going from Null to a valid user" do
    # create a Bug in Jira with no assignee
    issue, key = create_jira_issue({'Summary' => "Lemon Meringue pie", 'Assignee' => nil})
    issue.Assignee.should be_nil

    @jira.update(issue, {'Assignee' => JiraSpecHelper::DEFAULT_ASSIGNEE})
    upd_issue = @connection.find(key)
    @connection.get_value(upd_issue, 'Assignee').should == JiraSpecHelper::DEFAULT_ASSIGNEE
  end

  it "have a method to test require jira version" do

    args = {:min_major => 5, :min_minor => 2}

    @jira.send(:appropriate_jira_version,"6.0.0",args).should be_true
    @jira.send(:appropriate_jira_version,"5.2.0",args).should be_true
    @jira.send(:appropriate_jira_version,"4.2.0",args).should be_false

    @jira.send(:appropriate_jira_version,"5.2",args).should be_true
    @jira.send(:appropriate_jira_version,"4.2",args).should be_false
  end

  it "handle non-identical data type comparisons after create successfully" do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = RallyEIF::WRK::JiraRestConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
    @connector.field_mapping << FieldMap.new('PlanEstimate'.intern, 'Story Points'.intern, 'Both')

    fields = { :Name  => "Montgomery Fern Currency Gardens",
               :State => "Defined",
               :PlanEstimate => 22,
    }
    rally_story = @rc.create(fields)
    rally_oid   = @rc.get_value(rally_story, "ObjectID")
    rally_plan_estimate = @rc.get_value(rally_story, "PlanEstimate")

    @connector.copy_to_other({:artifact => rally_story})
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.should_not be_nil
    jira_issue.Summary.should  == @rc.get_value(rally_story, "Name")
    jira_issue.Status.should   == 'Open'
    jira_issue.RallyURL.should == "#{@rc.detail_url}/userstory/#{rally_oid}"
    jira_issue['Story Points'].should == rally_plan_estimate
  end

  it "return true from pre-copy on a Done issue in simplified workflow" do
    issue, key = create_jira_issue({'Summary' => "Oh no, I'm closed"})
    issue = @jira.update(issue, { "Status" => "Done"} )
    issue['Status'].should == "Done"
    @jira.pre_copy(issue).should == true
  end

  it "return false from pre-copy on a Closed issue in restricted workflow" do
    config = JiraSpecHelper::JIRA_ATTACHMENT_CONFIG_FILE.dup
    konfab = Konfabulator.new(config)
    jira = RallyEIF::WRK::JiraConnection.new(konfab.section("JiraConnection"))
    jira.connect()
    issue = jira.create({'Summary' => "Oh no, I'm closed"})
    issue = jira.update(issue, { "Status" => "Closed"} )
    issue['Status'].should == "Closed"
    jira.pre_copy(issue).should == false
  end

  it "handle explicit setting of IDFIeld for JiraConnection and successfully copy defect/bug" do
    config = JiraSpecHelper::JIRA_CONFIG_FILE
    altered = JiraSpecHelper::modify_config_data(config, 'JiraConnection', 'IDField', 'id', 'before', 'ExternalIDField')
    @konfab = Konfabulator.new(altered)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)

    fields = { :Name  => "Ludicrous flotsam arranged on Fulmanetti Arena roof must go",
               :State => "Submitted",
    }
    rally_story = @rc.create(fields)
    rally_oid   = @rc.get_value(rally_story, "ObjectID")

    @connector.copy_to_other({:artifact => rally_story})
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.should_not be_nil
    jira_issue.id.to_i.should > 0
    jira_issue.Summary.should  == @rc.get_value(rally_story, "Name")
    jira_issue.Status.should   == 'To Do'
    jira_issue.RallyURL.should == "#{@rc.detail_url}/defect/#{rally_oid}"

    issue, key = create_jira_issue({'Summary' => "Altered states in parallel universe need Ouija board treatment" },
                                   default_external_id=true)
    @connector.copy_to_rally({:artifact => issue})
    #rally_defect = @rc.find_by_external_id(key)
    rally_defect = @rc.find_by_external_id(issue.id)
    @rc.get_value(rally_defect, "Name").should ==  @jira.get_value(issue, "Summary")
    @rc.get_value(rally_defect, "State").should == "Submitted"
    @rc.get_value(rally_defect, "JiraKey").to_i.should > 0
  end

end
