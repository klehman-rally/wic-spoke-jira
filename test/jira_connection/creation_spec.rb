# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The JIRA Connection Issue Creation Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @connection = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @connection.connect()
  end

  it "should create a Bug and be able to find it by RallyId" do
    summary = "rudimentary issue summary"
    issue, key = create_jira_issue({'Summary' => summary})
    external_id_value = @jira.get_value(issue, "RallyID")
    found_issue = @jira.find(key)
    found_issue.should_not be_nil
    @jira.get_value(found_issue, 'Summary').should  == summary
    @jira.get_external_id_value(found_issue).should == external_id_value
  end

  it "should create a Bug and transition state to the desired state" do
    DEFAULT_ASSIGNEE = "devuser"
    fields = {}
    fields['Summary'] = "a Bug created and transitioned to the Closed state"
    fields['Status']  = "Done"
    fields['Assignee'] = DEFAULT_ASSIGNEE
    #fields['Resolution'] = 'Duplicate'
    bug = @jira.create(fields)
    found_bug = @jira.find(bug.key)
    found_bug.should_not be_nil
    found_bug.Status.should == "Done"
    found_bug.Resolution.should == 'Done'
  end

  it "should create a Bug with more than the minimal fields specified" do
    summary  = "an issue with more meat on the bone"
    issue_fields = { 'Summary'     => summary,
                     'Description' => "Description text for the Jira issue would go here...",
                     'Priority'    => "High",
                     'Reporter'    => "devuser",
                     'Project'     => "TST"
    }
    issue, key = create_jira_issue(issue_fields)
    found_issue = @jira.find(key)
    found_issue.should_not         be_nil
    found_issue.Summary.should     == summary
    found_issue.Reporter.should    == 'devuser'
    found_issue.Priority.should    == 'High'
    found_issue.project_key.should == 'TST'
    found_issue.Project.should     == 'Automated Testing'
  end

  it "should raise exception if the priority is not valid" do
    issue_fields = { 'Summary'  => "I have a bad priority setting...",
                     'Priority' => "Zebra"
    }
    lambda { issue, key = create_jira_issue(issue_fields) }.should raise_error(RecoverableException)
  end

  it "should raise exception if the reporter is not valid" do
    issue_fields = { 'Summary'  => "I have an invalid reporter value...",
                     'Reporter' => "fumanchu"
    }
    lambda { issue, key = create_jira_issue(issue_fields) }.should raise_error(RecoverableException)
  end

  it "should raise exception if the assignee is not valid" do
    issue_fields = { "Summary"  => "I have an invalid assignee value...",
                     "Assignee" => "casperghost"
    }
    lambda { issue, key = create_jira_issue(issue_fields) }.should raise_error(RecoverableException)
  end

  it "should create an issue with the corresponding status in Jira when the state is not the initial state" do
    issue_fields = { "Summary" => 'a test Bug with a non-initial status',
                     "Status"  => "In Progress"
    }
    issue, key = create_jira_issue(issue_fields)
    issue.Summary.should == "a test Bug with a non-initial status"
    issue.Status.should == 'In Progress'
  end

  it "should raise exception if a given an invalid Jira issue field name" do
    issue_fields = { "Summary"   => "I have an invalid field name...",
                     "Moosemeet" => "flank-steak"
    }
    lambda { issue, key = create_jira_issue(issue_fields) }.should raise_error(RecoverableException)
  end

  it "should Populate Story Points with an integer number" do

    issue_fields = { "Summary" => 'A test of Story Points',
                     "Status"  => "In Progress",
                     "Story Points" => 1
    }
    issue, key = create_jira_issue(issue_fields)
    issue.Summary.should == 'A test of Story Points'
    issue.Status.should == 'In Progress'
    (issue["Story Points"] == 1).should be_true

  end

  it "should Populate Story Points with an Floating point number" do

    issue_fields = { "Summary" => 'A test of Story Points as floating point',
                     "Status"  => "In Progress",
                     "Story Points" => 2.5
    }
    issue, key = create_jira_issue(issue_fields)
    issue.Summary.should == 'A test of Story Points as floating point'
    issue.Status.should == 'In Progress'
    issue["Story Points"].should == 2.5

  end

  it "should Populate Story Points with a integer point String" do

    issue_fields = { "Summary" => 'A test of Story Points as floating point',
                     "Status"  => "In Progress",
                     "Story Points" => "9"
    }
    issue, key = create_jira_issue(issue_fields)
    issue.Summary.should == 'A test of Story Points as floating point'
    issue.Status.should == 'In Progress'
    issue["Story Points"].should == "9".to_f

  end


  it "should Populate Story Points with a floating point String" do

    issue_fields = { "Summary" => 'A test of Story Points as floating point',
                     "Status"  => "In Progress",
                     "Story Points" => "6.5"
    }
    issue, key = create_jira_issue(issue_fields)
    issue.Summary.should == 'A test of Story Points as floating point'
    issue.Status.should == 'In Progress'
    issue["Story Points"].should == "6.5".to_f

  end



end
