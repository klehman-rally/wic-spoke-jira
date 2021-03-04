# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The JIRA Connection" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../.."))
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @jira_connection = JiraConnection.new(@konfab.section("JiraConnection"))
  end

  it "should have read its config file" do
    @jira_connection.url.should == JiraSpecHelper::JIRA_SERVER
    @jira_connection.user.should == "testuser"
    @jira_connection.password.should == "jiradev"
    @jira_connection.artifact_type.should == :bug
    @jira_connection.id_field.to_sym.should == :key
    @jira_connection.external_id_field.to_sym.should == :RallyID
    @jira_connection.project.should == "TST"
  end

  it "should properly have optional fields as nil" do
    konfab = Konfabulator.new(JiraSpecHelper::JIRA_NO_CROSSLINK_CONFIG)
    jc = JiraConnection.new(konfab.section("JiraConnection"))
    jc.url.should == JiraSpecHelper::JIRA_SERVER
    jc.user.should == "testuser"
    jc.password.should == "jiradev"
    jc.artifact_type.should == :bug
    jc.id_field.to_sym.should == :key
    jc.external_id_field.to_sym.should == :RallyID
    jc.external_item_link_field.should be_nil
    jc.external_end_user_id_field.should be_nil
    jc.project.should == "TST"
  end

end