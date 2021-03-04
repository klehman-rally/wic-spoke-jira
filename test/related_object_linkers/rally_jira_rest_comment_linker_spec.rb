# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'
require 'rallyeif/jira/utils/xanitize'

include JiraSpecHelper
include RallyEIF::WRK::FieldHandlers

describe "Rally Jira comment linker tests" do

  ON_DEMAND_JIRA = "https://alligator-tiers.atlassian.net"
  ON_DEMAND_USER = "nik.musaelian@broadcom.com",
  ON_DEMAND_PSWD = "qZcjfyZnY4V3DwnQAKvi237A"   # the security token for the ON_DEMAND_USER
  ON_DEMAND_ACCTID =  "5e5fd170ed743a0afe391af0"
  ON_DEMAND_PROJ = "SMO"
  ON_DEMAND_EXTERNAL_ID = "RallyID"

  before :all do
    #puts "Starting spec #{__FILE__}"
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../../.."))
    konfab = Konfabulator.new(JiraSpecHelper::JIRA_ATTACHMENT_CONFIG_FILE)
    @jira = JiraConnection.new(konfab.section("JiraConnection"))
    @jira.connect()
    @rally = RallyConnection.new(konfab.section("RallyConnection"))
    @rally.connect()
    @test_connector = Connector.new(konfab, @rally, @jira)
  end

  after :all do
    @jira.disconnect() if !@jira.nil?
  end

  it "should send comments from Jira to Rally" do
    #make an issue with a comment
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    @jira.add_comments(issue, [{:text => "test comment1"}])

    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    rally_discussion = @rally.get_comments(rally_item)
    rally_discussion.length.should == 1
    rally_discussion[0][:text].should include("test comment1")
  end

  it "should send comments from Jira to Rally with line breaks" do
    #make an issue with a comment that has multiple lines
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    @jira.add_comments(issue, [{:text => "test \n comment1"}])

    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    rally_discussion = @rally.get_comments(rally_item)
    rally_discussion.length.should == 1
    rally_discussion[0][:text].should include("<div>test </div><div> comment1</div>")
  end

  it "should detect a JIRA 6.x or 7.x comment that is already in a set of comments" do
    bogus_comment_time = (Time.now - 300).utc.iso8601
    target_comment = 'Blended <strong>whiskey</strong> has many fans'
    existing_comments = [{:text => "Plan 9 from outer space", :time => bogus_comment_time},
                         {:text => target_comment,            :time => bogus_comment_time}
                        ]

    # make a new issue in JIRA, add a comment via @jira.add_comments
    fields = { 'Description' => 'A simple test bug as vehicle for a comment' }
    issue, key = create_jira_issue(fields)

    comment_linker = RallyEIF::WRK::RelatedObjectLinkers::RallyJiraCommentLinker.new
    jira_comment = comment_linker.build_comment_text_jira({:text => target_comment, :time => bogus_comment_time, :author => "yeti@rallydev.com"})
    @jira.add_comments(issue, [jira_comment])
    jira_comment = @jira.get_comments(issue).first
    jira_comment[:text].should =~ /^RallyJiraConnector at: .* by:/
    jira_comment[:text].should =~ /added by CA Agile Central user:\s*\w+/
    comment_linker.artifact_has_comment?(existing_comments, jira_comment).should be_true
  end

  # it "should detect a JIRA OnDemand (1000.xxx.yy) comment that is already in a set of comments" do
  #   orig_config = JiraSpecHelper::JIRA_ATTACHMENT_CONFIG_FILE
  #   new_config  = JiraSpecHelper::modify_config_data(orig_config, 'JiraConnection', 'Url',       ON_DEMAND_JIRA,    'replace', 'Url')
  #   new_config  = JiraSpecHelper::modify_config_data(new_config,  'JiraConnection', 'User',      ON_DEMAND_USER,    'replace', 'User')
  #   new_config  = JiraSpecHelper::modify_config_data(new_config,  'JiraConnection', 'Password',  ON_DEMAND_PSWD,    'replace', 'Password')
  #   new_config  = JiraSpecHelper::modify_config_data(new_config,  'JiraConnection', 'AccountID', ON_DEMAND_ACCTID,  'replace', 'AccountId')
  #   new_config  = JiraSpecHelper::modify_config_data(new_config,  'JiraConnection', 'Project',   ON_DEMAND_PROJ,    'replace', 'Project')
  #   new_config  = JiraSpecHelper::modify_config_data(new_config,  'JiraConnection', 'ExternalIDField',  ON_DEMAND_EXTERNAL_ID, 'replace', 'ExternalIDField')
  #
  #   konfab = Konfabulator.new(new_config)
  #   jira = JiraConnection.new(konfab.section("JiraConnection"))
  #   jira.connect()
  #   rally = RallyConnection.new(konfab.section("RallyConnection"))
  #   rally.connect()
  #   test_connector = Connector.new(konfab, rally, jira)
  #
  #   bogus_comment_time = (Time.now - 300).utc.iso8601
  #   target_comment = 'Piled papers and dead pagers\nmake for an unholy mess!'
  #
  #   existing_comments = [{:text => "elliptical orbits carry galactic windbag messages", :time => bogus_comment_time},
  #                        {:text => target_comment,            :time => bogus_comment_time}
  #                       ]
  #   # make a new issue in JIRA, add a comment via @jira.add_comments
  #   fields = { 'Description' => 'Tumbleweeds drifting across the landscape', 'Assignee' => 'hilary' }
  #   issue, key = create_jira_issue(fields, false, jira)
  #
  #   comment_linker = RallyEIF::WRK::RelatedObjectLinkers::RallyJiraCommentLinker.new
  #   jira_comment = comment_linker.build_comment_text_jira({:text => target_comment, :time => bogus_comment_time, :author => "yeti@rallydev.com"})
  #   jira.add_comments(issue, [jira_comment])
  #   jira_comment = jira.get_comments(issue).first
  #   jira_comment[:text].should =~ /^RallyJiraConnector at: .* by:/
  #   jira_comment[:text].should =~ /added by CA Agile Central user:\s*\w+/
  #   comment_linker.artifact_has_comment?(existing_comments, jira_comment).should be_true
  # end

  it "should send comments from Rally to Jira" do
    fields = { 'Description' => "Test discussions Rally to Jira"}
    defect = create_rally_artifact(@rally, fields)
    #actual text from a Rally comment
    rally_comment_txt = "test comment&nbsp;<div>second line</div> <div>in Rally 3</div>"
    @rally.add_comments(defect[0], [{:text => rally_comment_txt}])
    updated_de = defect[0].refresh
    project_name = updated_de.Project['_refObjectName']  # we have to compensate for refresh turning Project (name string) back into a RallyObject
    updated_de['Project'] = project_name
    jira_item = @test_connector.copy_to_other({:artifact => updated_de})
    jira_comments = @jira.get_comments(jira_item)
    jira_comments.length.should > 0
    #jira_comments[0][:text].each_byte {|bt| print bt,"-"}
    jira_comments[0][:text].should =~ /test comment second line\n in Rally 3\n/
  end

  it "should not do anything with no comments in Jira or Rally" do
    #Rally to Jira
    fields = { 'Description' => "Test attachment Rally to Jira"}
    defect = create_rally_artifact(@rally, fields)
    jira_item = @test_connector.copy_to_other({:artifact => defect[0]})
    jira_comments = @jira.get_comments(jira_item)
    jira_comments.length.should == 0

    #Jira to Rally
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)

    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    rally_discussion = @rally.get_comments(rally_item)
    rally_discussion.length.should == 0
  end

  it "should be idempotent when running with multiple updates" do
    # create in Jira
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    @jira.add_comments(issue, [{:text => "test comment1 \n line 2"}])

    #puts "-------------- copy to rally"
    # copy to Rally
    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    last_connector_run = Time.now.utc

    #puts "--------------- update jira issue Description field"
    issue = @jira.find(key)

    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID updated' }
    modified_work_item = @jira.update(issue, fields)

    # update Jira to Rally
    rally_item2 = @test_connector.update_rally({:artifact=>issue})
    rally_item2.should_not be_nil
    rally_item.refresh
    rally_item_discussion = @rally.get_comments(rally_item)
    rally_item_discussion.length.should == 1

    #puts "----------------- update jira"
    # update Rally to Jira
    updated_jira_issue = @test_connector.update_other({:artifact => rally_item, :last_run => last_connector_run})
    updated_jira_issue.should be_nil  # as the only change in the Rally item was Description which was triggered by the JIRA isssue change
  end

  it "should add comments on both Rally and Jira from each on update" do
    #create issue in Jira
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID'}
    issue, key = create_jira_issue(fields)
##    puts "----------------- JIRA issue created"

#add comment Jira
    initial_jira_comment = "test comment1"
    @jira.add_comments(issue, [{:text => initial_jira_comment}])
##    puts "----------------- initial comment added to JIRA issue |#{initial_jira_comment}|"

#copy to Rally
##    puts "----------------- copying JIRA issue to Rally ..."
##$stdout.flush()
    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    last_connector_run = Time.now.utc
##    puts "----------------- JIRA issue copied to Rally"

#add comment in Jira
    second_jira_comment = "test comment 2 in jira"
    @jira.add_comments(issue, [{:text => second_jira_comment}])
##    puts "----------------- second comment added to JIRA issue |#{second_jira_comment}|"

#add comment in Rally
    additional_rally_comment = "test comment in Rally"
    @rally.add_comments(rally_item, [{:text => additional_rally_comment}])
    rally_item.refresh
##    puts "----------------- comment added to Rally issue |#{additional_rally_comment}|"

#update Jira
##    puts "----------------- updating JIRA issue from Rally issue ..."
##$stdout.flush()
    updated_jira_issue = @test_connector.update_other({:artifact => rally_item, :last_run => last_connector_run})
##    puts "----------------- pushed update to Rally issue over to JIRA issue"
    jira_issue = @jira.find(key)
    jira_comments = @jira.get_comments(jira_issue)
    jira_comments.length.should == 3

    #update Rally
    ##    puts "----------------- updating Rally issue from JIRA issue ..."
    ##$stdout.flush()
    rally_updated_item = @test_connector.update_rally({:artifact=>jira_issue})
    ##    puts "----------------- pushed update to JIRA issue over to Rally issue"
    rally_updated_item.should be_nil
    rally_item.refresh
    rally_item_discussion = @rally.get_comments(rally_item)
    rally_item_discussion.length.should == 3
  end


  it "will maintain comments on both systems" do
    #create issue in Jira
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
##    puts "----------------- JIRA issue created"

#add comment Jira
    initial_jira_comment = "test comment1"
    @jira.add_comments(issue, [{:text => initial_jira_comment}])
##    puts "----------------- initial comment added to JIRA issue |#{initial_jira_comment}|"

#copy to Rally
##    puts "----------------- copying JIRA issue to Rally ..."
##$stdout.flush()
    rally_item = @test_connector.copy_to_rally({:artifact => issue})
    rally_item.refresh()
    rally_item.should_not be_nil
    last_connector_run = Time.now.utc
##    puts "----------------- JIRA issue copied to Rally"

#add comment in Jira
    second_jira_comment = "test comment 2 in jira"
    @jira.add_comments(issue, [{:text => second_jira_comment}])
##    puts "----------------- second comment added to JIRA issue |#{second_jira_comment}|"

#add comment in Rally
    additional_rally_comment = "test comment in Rally"
    @rally.add_comments(rally_item, [{:text => additional_rally_comment}])
    rally_item.refresh
##    puts "----------------- comment added to Rally issue |#{additional_rally_comment}|"

#update Jira
##    puts "----------------- updating JIRA issue from Rally issue ..."
##$stdout.flush()
    updated_jira_issue = @test_connector.update_other({:artifact => rally_item, :last_run => last_connector_run})
##    puts "----------------- pushed update to Rally issue over to JIRA issue"
    jira_issue = @jira.find(key)
    jira_comments = @jira.get_comments(jira_issue)
    jira_comments.length.should == 3

    #update Rally
    ##    puts "----------------- updating Rally issue from JIRA issue ..."
    ##$stdout.flush()
    updated_rally_issue = @test_connector.update_rally({:artifact=>jira_issue})
    last_connector_run = Time.now.utc
    ##    puts "----------------- pushed update to JIRA issue over to Rally issue"
    updated_rally_issue.should be_nil
    rally_item.refresh
    rally_item_discussion = @rally.get_comments(rally_item)
    rally_item_discussion.length.should == 3
    ##
    ##  2012-01-31
    ##  here's some additional iterations of both ways updating to make sure that
    ##  no additional comments are added by the connector
    ##

    @rally.update(rally_item, {"Priority" => 'Low', "Description" => 'just in case'})
    rally_item.refresh
    updated_jira_issue = @test_connector.update_other({:artifact => rally_item, :last_run => last_connector_run})
    jira_comments = @jira.get_comments(updated_jira_issue)
    jira_comments.length.should == 3

    updated_rally_issue = @test_connector.update_rally({:artifact=>jira_issue})
    rally_item.refresh
    rally_item_discussion = @rally.get_comments(rally_item)
    rally_item_discussion.length.should == 3

##

  end

  it "should deal with a complicated discussion post from Rally" do
    complicated_post = 'some <font color="#00ff00">crazy d</font>iscussion <div>text <i>in some lines</i> italic</div> <div><b>with lots</b></div> <div>o<span style="background-color: rgb(255, 153, 0);">f line</span>s</div> <div><a href="http://www.google.com">www.google.com</a><br /></div>'

    fields = { 'Description' => "Test discussions Rally to Jira"}
    defect = create_rally_artifact(@rally, fields)
    #actual text from a Rally comment
    @rally.add_comments(defect[0], [{:text => complicated_post }])
    updated_de = defect[0].refresh
    project_name = updated_de.Project['_refObjectName']  # we have to compensate for refresh turning Project (name string) back into a RallyObject
    updated_de['Project'] = project_name  # and furthermore assignment to a RallyObject attribute can't be dot access, must be struct indexed, ie foo['Project'] = 'some new value'
    jira_item = @test_connector.copy_to_other({:artifact => updated_de})
    jira_comments = @jira.get_comments(jira_item)
    jira_comments.length.should > 0
    jira_comments.length.should == 1
    jira_comments[0][:text].should include("some crazy discussion text in some lines italic\n with lots\n of lines\n www.google.com\n")

##    puts "----------------- updating JIRA issue from Rally issue ..."
    updated_jira_issue = @test_connector.update_other({:artifact => updated_de})
##    puts "----------------- pushed update to Rally issue over to JIRA issue"
    upd_jira_comments = @jira.get_comments(jira_item)
##
##    cn = 1
##    for jira_comment in upd_jira_comments
##      puts "\n JIRA issue comment ##{cn}"
##      puts "  time: %s"    % jira_comment[:time]
##      puts "  text: %s"    % jira_comment[:text]
##      puts "  author: %s"  % jira_comment[:author]
##      cn += 1
##    end
##
    upd_jira_comments.length.should == 1

    #update Rally
    rally_item2 = @test_connector.update_rally({:artifact=>jira_item})
    rally_item2.should_not be_nil
    rally_item_discussion = @rally.get_comments(rally_item2)
    rally_item_discussion.length.should == 1
  end

end
