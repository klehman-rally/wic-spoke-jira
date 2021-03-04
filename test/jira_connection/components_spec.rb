# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe 'JIRA components fields tests' do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
    @jira = nil
    @rc = nil
    @connector = nil
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_COMPONENTS_FIELD_CONFIG_FILE)
    @rc = RallyEIF::WRK::RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @connection = @jira
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
  end

  after(:each) do
    @jira.disconnect() if !@jira.nil?
    @rc.disconnect()   if !@rc.nil?
  end

  it "should map a single component value already defined in JIRA to a JIRA issue Component/s field" do
    # create a Rally defect with a valid FoundInBuild value
    fields = { 'Name'     => "Walla Walla in Washington",
               'State'    => "Submitted",
               'Components'  => "Starboard Foot"
    }
    rally_defect  = @rc.create(fields)
    rally_oid     = @rc.get_value(rally_defect, "ObjectID")
    components    = @rc.get_value(rally_defect, "Component/s")

    # copy Rally defect to Jira bug
    @connector.copy_to_other({:artifact => rally_defect})

    # find bug in Jira and verify that the Components value is "Starboard Foot"
    issue = @jira.find_by_external_id(rally_oid)
    issue["Component/s"].should == "Starboard Foot"
  end

  it "update a multiple component value already defined in JIRA to a JIRA issue Component/s field" do
    # create a JIRA Bug with a valid Component/s value, and make no attempt to set a non-initial Status value
    fields = { 'Summary'     => "Disneyland in CA better then Disneyworld in FL",
               'Component/s'  => "Starboard Foot"
    }
    jira_bug    = @jira.create(fields)
    @jira.get_value(jira_bug, "Component/s").should == "Starboard Foot"

    # copy Jira bug to Rally defect
    @connector.copy_to_rally({:artifact => jira_bug})

    # Find Defect in Rally and test.
    defect = @rc.find_by_external_id(jira_bug.key)
    @rc.get_value(defect,"Components").should == "Starboard Foot"

  end

end
