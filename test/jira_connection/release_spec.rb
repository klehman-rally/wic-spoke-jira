# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The JIRA Custom field for version Tests" do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
    @jira = nil
    @rc = nil
    @connector = nil
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_TARGET_RELEASE_CONFIG_FILE)
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

  it "should create an issue in Rally with a valid Release value and transfer to JIRA" do
    # create a Rally defect with a valid Release
    fields = { 'Name'    => "Valvoline oil change",
               'State'   => "Submitted",
               'Release' => 'lime'
             }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    rally_release = @rc.get_value(rally_defect, "Release")
    #puts "The Rally Defect Release value is |#{rally_release}|"
    #lambda { rally_release = @rc.get_value(rally_defect, "Release")}.should raise_error(NoMethodError)

    # copy Rally defect to Jira bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find bug in Jira and verify that the TargetRelease value is "lime"
    issue = @jira.find_by_external_id(rally_oid)
    issue["Target Release"].should == "lime"
  end

  it "should create a bug in JIRA with a Target Release version and copy the defect to Rally with the correct Release version" do
    bug_info = { 'Summary' => "Imaginary Hawaiian Girlfriend",
                 "Target Release" => "apple",
               }
    bug, key = create_jira_issue(bug_info, default_external_id=true)
    # copy Jira bug to Rally defect
    @connector.copy_to_rally({:artifact => bug})
    # Rally defect should show a Release of "apple"
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.Release.should == "apple"
  end

end


