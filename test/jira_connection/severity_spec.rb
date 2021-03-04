# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The JIRA Severity field handling Tests" do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
    @jira = nil
    @rc = nil
    @connector = nil
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = JiraConnection.new(@konfab.section("JiraConnection"))
    @connection = @jira
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
  end

  after(:each) do
    @jira.disconnect() if !@jira.nil?
    @rc.disconnect()   if !@rc.nil?
  end

  it "should create an issue in JIRA with no severity and transfer to Rally resulting in None severity on Rally defect" do
    # create Jira issue (no severity set)
    issue, key = create_jira_issue({'Summary' => "Alcorn State Nutjobs"}, default_external_id=true)
    # copy Jira Bug to Rally defect
    @connector.copy_to_rally({:artifact => issue})
    # Rally defect should show default severity?
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.Severity.should == 'None'
  end

  it "should create an issue in Rally with no severity set and transfer to JIRA" do
    # assumes that Rally severity of "None" has been mapped to Jira severity value of "Trivial" in the config.xml
    # create a Rally defect with a no severity value
    fields = { 'Name'        => "Pepperdine Scoville Units",
               'Priority'    => "Normal",
               'State'       => "Submitted",
            }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    rally_severity = @rc.get_value(rally_defect, "Severity")
    #puts "The Rally Defect Severity value is |#{rally_severity}|"
    #lambda { rally_severity = @rc.get_value(rally_defect, "Severity")}.should raise_error(NoMethodError)

    # copy Rally defect to Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find Bug in Jira and verify that the severity value is "None"
    issue = @jira.find_by_external_id(rally_oid)
    issue.Summary.should  == rally_defect.Name
    issue.Severity.should == "Cosmetic"
  end

  it "should create an issue in Rally with severity Cosmetic and transfer to JIRA" do
    # create a Rally defect with a severity of 'Cosmetic'
    fields = { 'Name'        => "Manhattan Beauty Queens",
               'Priority'    => "Normal",
               'State'       => "Submitted",
               'Severity'    => "Cosmetic",
            }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    # copy Rally Defect to Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})

    # Jira Dug should have 'Cosmetic' as the severity
    issue = @jira.find_by_external_id(rally_oid)
    issue.Summary.should  == rally_defect.name
    issue.Severity.should == "Cosmetic"
  end

  it "should change the severity to a non-default value in Rally and update JIRA with the correct severity" do
    # create a Rally defect with a default severity value
    fields = { 'Name'        => "Blatherskite Blabbermounts",
               'Priority'    => "Normal",
               'State'       => "Submitted",
             }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    # copy Rally Defect to Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc
    # find the corresponding Bug in Jira
    issue = @jira.find_by_external_id(rally_oid)
    # now update the Rally defect to have a non default value
    @rc.update(rally_defect, {'Severity' => 'Minor Problem'})
    sleep(1)
    rally_defect = @rc.find_by_external_id(issue.key)
    # trigger the update of the corresponding Bug in Jira
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    # Jira Bug should have 'Minor' as the severity
    sleep(1)
    issue = @jira.find_by_external_id(rally_oid)
    issue.Summary.should  == rally_defect.name
    issue.Severity.should == "Minor Problem"
  end

  it "should change the severity to None in Rally and update JIRA with the correct severity" do
    # create a Rally defect with a non-default severity value
    fields = { 'Name'        => "Crescendimum Carhops",
               'Priority'    => "Normal",
               'State'       => "Submitted",
               'Severity'    => "Major Problem"
            }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    # copy Rally defect to Jira Bug
    issue = @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc
    sleep(1)
    issue.Severity.should == "Major Problem"

    # find the corresponding Bug in Jira
    issue = @jira.find_by_external_id(rally_oid)

    # update the Rally defect to have a severity of None
    @rc.update(rally_defect, {'Severity' => "None"})
    sleep(1)
    rally_defect = @rc.find_by_external_id(issue.key)
    rally_defect.read()
    severity = @rc.get_value(rally_defect, "Severity")

    sleep(1)
    # trigger the update of the corresponding Bug in Jira
    issue = @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})

    # Jira Bug should have "None" as the severity
    issue = @jira.find_by_external_id(rally_oid)
    issue.Summary.should  == rally_defect.name
    issue.Severity.should == "Cosmetic"
  end

  it "should change the severity and status in Rally and update JIRA correctly" do

    # create a Rally defect with a non-default severity value
    fields = { 'Name'        => "Denison Demonizers",
               'Priority'    => "Normal",
               'State'       => "Submitted",
               'Severity'    => "Crash/Data Loss"
    }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    # copy the Rally defect to a Jira Bug
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc

    # find the corresponding Bug in Jira
    issue = @jira.find_by_external_id(rally_oid)
    issue.Severity.should == "Crash/Data Loss"
    # update the Rally defect to have a severity that is not the default value (and not None)
    #   and update the state of the Rally defect to another state
    @rc.update(rally_defect, {'State' => "Fixed", 'Severity' => "Minor Problem"})
    rally_defect = @rc.find_by_external_id(issue.key)
    rally_defect.read()
    severity = @rc.get_value(rally_defect, "Severity")

    # trigger the update of the corresponding Bug in Jira
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    sleep(1)
    # Jira Bug should have "Minor" as the severity and should have progressed through workflow to desired status ("5")
    issue = @jira.find_by_external_id(rally_oid)
    issue.Summary.should == rally_defect.name
    issue.Severity.should == "Minor Problem"
  end

  it "should change the severity of a Bug to the Cosmetic value in Jira and update Rally with severity of None" do
    # create Jira Bug (with severity of "Minor")
    issue, key = create_jira_issue({ 'Summary'   => "Monongehela Community Remedial",
                                     'Severity'  => "Minor Problem"
                                   },
                                   default_external_id=true)
    # copy Jira Bug to Rally defect
    rally_defect = @connector.copy_to_rally({:artifact => issue})
    rally_defect.Severity.should == "Minor Problem"

    # Rally defect should show default severity?
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.Severity.should == 'Minor Problem'

    #update the Jira Bug to take the severity value back to the default of None
    @jira.update(issue, {'Severity' => "Cosmetic"})
    sleep(1)
    issue = @jira.find(key)  # to see if the severity value has changed
    issue.Severity.should == "Cosmetic"

    # trigger the update of the corresponding defect in Rally
    @connector.update_rally({:artifact=>issue})
    sleep(1)
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.Severity.should == 'None'
  end

end


