# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "JIRA non-bug issue type connection" do
  #the standard non-bug issue types are 'New Feature', 'Improvement' and 'Task'
  #We've also added for testing purposes a Custom Issue type called 'Regulation'

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    @connection = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @jira.connect()
  end

  it "should create a New Feature issue and find it by id" do
    summary = "#{@jira.artifact_type} item for testing purposes, issue psuedo-serial ##{Time.now.usec.to_s}"
    issue_fields = {}
    issue_fields['Summary']  = summary
    issue_fields['Assignee'] = 'yeti'
    issue, key = create_jira_issue(issue_fields)
    found_issue = @jira.find(key)
    external_id_value = @jira.get_value(found_issue, "RallyID")
    @jira.get_value(found_issue, 'Summary').should   == summary
    @jira.get_external_id_value(found_issue).should == external_id_value
  end

  it "should create a Regulation issue with more than the minimal fields specified" do
    @jira.artifact_type = "Regulation"
    summary  = "A #{@jira.artifact_type} with more meat on the bone, psuedo-serial ##{Time.now.usec.to_s}"
    issue_fields = { 'Summary'     => summary,
                     'Description' => "Description text for the Jira Regulation issue would go here...",
                     'Priority'    => "Highest",
                     'Reporter'    => "devuser",
                     'Project'     => "NFI"
    }
    issue, key = create_jira_issue(issue_fields)
    found_issue = @jira.find(key)
    found_issue.should_not be_nil
    external_id_value = @jira.get_value(found_issue, "RallyID")
    @jira.get_value(found_issue, 'Summary').should == summary
    @jira.get_external_id_value(found_issue).should == external_id_value
  end

  it "should successfully update the New Feature issue summary (and no other issue fields)" do
    @jira.artifact_type = "New Feature"
    issue, key = create_jira_issue({'Summary' => 'original summary text'})
    upd_summary_text = 'The updated summary text'
    fields = {'Summary' => upd_summary_text}
    @jira.update(issue, fields)
    issue = @connection.find(key)
    @connection.get_value(issue, 'Summary').should == fields['Summary']
  end

  it "should create/update a bug with more than just minimal fields populated" do
    @jira.artifact_type = "Regulation"
    issue, key = create_jira_issue({'Summary' => 'The Original Sin'})
    fields = {'Summary'     => 'The updated summary text',
              'Description' => 'The updated description text.',
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
             }
    @jira.update(issue, fields)
    issue = @jira.find(key)
    @jira.get_value(issue, 'Summary').should     == fields['Summary']
    @jira.get_value(issue, 'Description').should == fields['Description']
    @jira.get_value(issue, 'Priority').should    == fields['Priority']
    @jira.get_value(issue, 'Reporter').should    == fields['Reporter']
  end

end

