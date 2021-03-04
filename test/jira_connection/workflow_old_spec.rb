# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The Rally-JIRA Connector workflow tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))

    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<Project>TST</Project>','<Project>RW</Project>')
    config.sub!('<WorkflowFile>configs/simplified_workflow.xml</WorkflowFile>','<WorkflowFile>configs/jira_workflow.xml</WorkflowFile>')

    @konfab = Konfabulator.new(config)
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

  expected_results = []
  expected_results.push(JiraSpecHelper::JIRA_STATUS_INPROGRESS)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_RESOLVED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_CLOSED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_OPEN)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_OPEN)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_RESOLVED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_RESOLVED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_INPROGRESS)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_INPROGRESS)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_CLOSED)

  #expected_results.push(JiraSpecHelper::JIRA_STATUS_CLOSED)

  expected_results.push(JiraSpecHelper::JIRA_STATUS_OPEN)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_RESOLVED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_INPROGRESS)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_OPEN)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_CLOSED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_RESOLVED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_OPEN)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_CLOSED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_INPROGRESS)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)
  expected_results.push(JiraSpecHelper::JIRA_STATUS_REOPENED)

  make_random = Random.new(23)

  expected_results.each do |new_status|
    it "should update the JIRA status to #{new_status}" do
      issue = @jira.find(@issue.key)
      issue.should_not be_nil
      old_status = issue.Status

      update_fields = {'Status' => new_status}
      if new_status == JiraSpecHelper::JIRA_STATUS_RESOLVED
         update_fields['Resolution'] = "Won't Fix"
      end

      new_summary = 'workflow_spec-created issue created ' + (make_random.rand * 100000).to_s
      update_fields['Summary'] = new_summary
      upd_issue = @jira.update(issue, update_fields)

      @issue = @jira.find(upd_issue.key)
      @issue.should_not be_nil

      @issue.Status.should == new_status

      if new_status != old_status and old_status != JIRA_STATUS_CLOSED and new_status != JIRA_STATUS_CLOSED
        @issue.Summary.should == new_summary
      end

    end
  end

end
