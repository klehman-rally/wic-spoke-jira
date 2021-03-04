# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe 'Jira Connection Utilities Tests' do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
    @jira = nil
  end

  after(:each) do
    @jira.disconnect() if !@jira.nil?
  end

 it "should successfully read the config.xml file" do
     @jira = jira_connect(JiraSpecHelper::JIRA_CONFIG_FILE)

     @jira.project.should == 'TST'
     @jira.url.should     == JIRA_SERVER
 end

 it "should set external id correctly for Rally object" do
     @jira = jira_connect(JiraSpecHelper::JIRA_CONFIG_FILE)
     @jira.set_external_id_fields({}, "123").should == {'RallyID' => "123"}
 end

 it "should fail if external id is not found for Jira Bug" do
     @jira = jira_connect(JiraSpecHelper::JIRA_CONFIG_FILE)
     @jira.artifact_type = 'Bug'
     @jira.external_id_field = nil
     @jira.validate().should == false
 end

  
end

