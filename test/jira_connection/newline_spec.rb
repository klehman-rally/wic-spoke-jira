# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper
include RallyEIF::WRK::FieldHandlers

describe "The JIRA newline field handler" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @rally = RallyConnection.new(@konfab.section("RallyConnection"))
    @rally.connect()
    @jira = JiraConnection.new(@konfab.section("JiraConnection"))
    @jira.connect()
    @connector = Connector.new(@konfab, @rally, @jira)
  end

  it "should copy an issue with newlines in description from JIRA to Rally and back" do
    @jira.register_field_handler(JiraNewlineFieldHandler.new(:Description))
    description = 'Paragraph1\n\nParagraph2'
    issue, key = create_jira_issue({'Summary' => "Newline test issue again", 'Description' => description})
    issue.Description.should == description

    @connector.copy_to_rally({:artifact => issue})
    last_connector_run = Time.now.utc

    rally_defect = @rally.find_by_external_id(key)
    rally_defect_first_mod   = @rally.get_value(rally_defect, "LastUpdateDate")
    rally_defect_description = @rally.get_value(rally_defect, "Description")
    rally_defect_description.should == description.gsub(/\n/, '<br />')

    # update the defect in Rally, changing the Name
    # retrieve it back, validating the change in Name value and the last_modified time
    @rally.update(rally_defect, {:Name => "Updated"})
    rally_defect = @rally.find_by_external_id(key)
    updated_rally_defect_last_mod = @rally.get_value(rally_defect, "LastUpdateDate")
    updated_rally_defect_name     = @rally.get_value(rally_defect, "Name")
    updated_rally_defect_desc     = @rally.get_value(rally_defect, "Description")
    updated_rally_defect_last_mod.should > rally_defect_first_mod
    updated_rally_defect_name.should == "Updated"

    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    rally_oid = @rally.get_value(rally_defect, "ObjectID")
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.Summary.should == @rally.get_value(rally_defect, "Name")
    jira_bug.Description.should ==
       @rally.get_value(rally_defect, "Description").gsub(/<br \/>/, "\n").gsub(/<br>/, "\n")

  end

end
