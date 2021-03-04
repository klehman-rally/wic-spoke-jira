# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe 'JIRA versions fields tests' do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
    @jira = nil
    @rc = nil
    @connector = nil
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_VERSIONS_FIELDS_CONFIG_FILE)
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

  it "should map a single version value already defined in JIRA to a JIRA issue version field" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Name'     => "Pennzoil is in Arnold Palmer country",
               'State'    => "Submitted",
               'FoundInBuild'  => "lime"
    }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    foundInBuild  = @rc.get_value(rally_defect, "FoundInBuild")

    # copy Rally defect to Jira bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find bug in Jira and verify that the Affects Version/s value is "lime"
    issue = @jira.find_by_external_id(rally_oid)
    issue["Affects Version/s"].should == "lime"
  end

  it "should map a multiple version values with spaces already defined in JIRA to a JIRA issue versions field " do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Name'     => "Benetelli's Fine Foods, since 1879",
               'State'    => "Submitted",
               'FoundInBuild'  => "apple, lime"
    }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    foundInBuild  = @rc.get_value(rally_defect, "FoundInBuild")

    # copy Rally defect to Jira bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find bug in Jira and verify that the Affects Version/s value is "lime"
    issue = @jira.find_by_external_id(rally_oid)
    issue["Affects Version/s"].split(",").sort.should == "apple,lime".split(",").sort
  end

  it "should map a multiple version values already defined in JIRA to a JIRA issue versions field" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Name'     => "Benetelli's Fine Foods, since 1879",
               'State'    => "Submitted",
               'FoundInBuild'  => "apple,lime"
    }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    foundInBuild  = @rc.get_value(rally_defect, "FoundInBuild")

    # copy Rally defect to Jira bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find bug in Jira and verify that the Affects Version/s value is "lime"
    issue = @jira.find_by_external_id(rally_oid)
    issue["Affects Version/s"].split(",").sort.should == "apple,lime".split(",").sort
  end

  it "should raise an exception on an attempt to copy a Rally issue with a FoundInBuild value that is undefined in JIRA" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Name'     => "Pennzoil is in Arnold Palmer country",
               'State'    => "Submitted",
               'FoundInBuild'  => "grape"
    }
    rally_defect  = @rc.create(fields)
    foundInBuild  = @rc.get_value(rally_defect, "FoundInBuild")

    logfile = YetiTestUtils::OutputFile.new("rallylog.log")
    # attempt to copy Rally defect to Jira bug, but detect that it can't be done because the prospective Affects Version/s value is invalid
    jira_bug = @connector.copy_to_other({:artifact => rally_defect})
    jira_bug.should be_nil
    logfile.readlines.grep(/ERROR.* Unable to create new JIRA Bug, "grape" not an allowed value for the Affects Version\/s field/).should_not be_empty
  end

  it "should map a single version value already defined in JIRA to a Rally FoundInBuild field" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Summary'   => "Neverland never was a kid's paradise",
               'Status'    => "In Progress",
               'Affects Version/s'  => "lime"
    }
    jira_bug  = @jira.create(fields)
    affects_versions  = jira_bug["Affects Version/s"]

    # copy JIRA bug to Rally defect
    @connector.copy_to_rally({:artifact => jira_bug})

    # find defect in Rally and verify that the FoundInBuild value is "lime"
    defect = @rc.find_by_external_id(jira_bug.key)
    @rc.get_value(defect, 'FoundInBuild').should == "lime"
  end

  it "should map a multiple version values already defined in JIRA to the Rally FoundInBuild field" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Summary'   => "JP was missed today.",
               'Status'    => "In Progress",
               'Affects Version/s'  => "lime, orange"
    }
    jira_bug  = @jira.create(fields)
    affects_versions  = jira_bug["Affects Version/s"]

    # copy JIRA bug to Rally defect
    @connector.copy_to_rally({:artifact => jira_bug})

    # find defect in Rally and verify that the FoundInBuild value is "lime"
    defect = @rc.find_by_external_id(jira_bug.key)
    @rc.get_value(defect, 'FoundInBuild').include?("lime").should be_true
    @rc.get_value(defect, 'FoundInBuild').include?("orange").should be_true
  end

end
