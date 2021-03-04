# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "JIRAConnection non-bug restrictive workflow status changes" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))

    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))

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

  it "should have correctly read the non-bug workflow file" do
    @jira.workflow['Step'].length.should == 5
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
  non_bug_types = ['New Feature', 'Regulation']

  non_bug_types.each do |iss_type|
    expected_results.each do |new_status|
      it "should update the JIRA status to #{new_status}" do

        issue = @jira.find(@issue.key)
        issue.should_not be_nil
        old_status = issue.Status

        upd_fields = {'Status' => new_status}
        if new_status == JiraSpecHelper::JIRA_STATUS_RESOLVED || new_status == JiraSpecHelper::JIRA_STATUS_CLOSED
          upd_fields['Resolution'] = "Won't Fix"
        end

        new_summary = 'non_bug_workflow_spec-created issue created ' + (make_random.rand * 100000).to_s
        upd_fields['Summary'] = new_summary
        upd_issue = @jira.update(issue, upd_fields)

        @issue = @jira.find(upd_issue.key)
        @issue.should_not be_nil

        @issue.Status.should == new_status

        #if new_status != old_status and old_status != JIRA_STATUS_CLOSED and new_status != JIRA_STATUS_CLOSED
          @issue.Summary.should == new_summary
        #end

      end
    end
  end

end


