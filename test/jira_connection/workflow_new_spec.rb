# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The Rally-JIRA Connector workflow tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))

    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @jira = JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect().should be_true

    @fields = {'Summary' => "summary text for a test item"}
    @fields['Assignee'] = 'yeti'
    @issue = @jira.create(@fields)
    @issue.should_not be_nil

    #connect as different user to make sure connector user can Start Progress on issue not assigned to it
    @jira.user     = 'devuser'
    @jira.password = 'jiradev'
    @jira.connect().should be_true
  end

  it "should correctly read the custom workflow file" do
    konfab = Konfabulator.new(JiraSpecHelper::JIRA_CUSTOM_WORKFLOW_CONFIG_FILE)
    jira = JiraConnection.new(konfab.section("JiraConnection"))
    jira.workflow['Step'].length.should == 6
  end

  it "should have correctly read the main workflow file" do  # as of 2016-09-07 the main workflow file is the JIRA 7 simplified workflow
    konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    jira = JiraConnection.new(konfab.section("JiraConnection"))
    jira.workflow['Step'].length.should == 4
  end


  it "should log an error for a failed transition to an isolated transition" do

    # Create JIRA Issue

    fields = { 'Description' => 'A simple test Bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    found_issue = @jira.find(key)
    found_issue.should_not be_nil

    # Valid transition, no raise

    new_status = JiraSpecHelper::JIRA_STATUS_DONE
    update_fields = {'Status' => new_status}
    update_issue = @jira.update(issue, update_fields)

    # Invalid transition, should raise

    new_status = JiraSpecHelper::JIRA_STATUS_ISOLATED
    update_fields = {'Status' => new_status}

    lambda do
      update_issue = @jira.update(update_issue, update_fields)
    end.should raise_error(RecoverableException, /No transition to JIRA status IsolatedTransition found for current JIRA status |Done|/)

  end

  it "log an error for a defect's failed transition" do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CORNER_CASE_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)

    # create a Rally defect with a valid FoundInBuild value
    fields = {
      'Name'      => 'Name',
      'State'     => 'Submitted',
      'Owner'     => 'yeti@rallydev.com'
    }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    foundInBuild  = @rc.get_value(rally_defect, "FoundInBuild")

    # copy Rally defect to Jira bug
    rally_jest_bug = @connector.copy_to_other({:artifact => rally_defect})

    # observe that the bug is updated with the corresponding stating
    new_status = JiraSpecHelper::JIRA_STATUS_ISOLATED
    update_fields = {'Status' => new_status}

    lambda{
      update_issue = @jira.update(rally_jest_bug, update_fields)
    }.should raise_error(RecoverableException, /No transition to JIRA status |IsolatedTransition| found for current JIRA status |Open|/)

    @jira.disconnect() if !@jira.nil?
    @rc.disconnect()   if !@rc.nil?
  end

  # this spec is no longer needed since we do not rely on reading of FinalStatus from xml config file
  # it "pick final Status from xml config file" do
  #   config = JiraSpecHelper::load_xml(JiraSpecHelper::JIRA_ATTACHMENT_CONFIG_FILE)
  #   jira = RallyEIF::WRK::JiraConnection.new(config)
  #   jira.final_status.should == "Closed"
  # end

end
