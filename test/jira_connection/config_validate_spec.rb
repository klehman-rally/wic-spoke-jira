# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper
include RallyEIF::WRK

COCO_TEST_CONFIG = %{<?xml version="1.0"?>
<!-- Rally Connector Configuration v0.6.4-->

<Config>
    <RallyConnection>
        <Url>https://rally1.rallydev.com/</Url>
        <User>yeti@rallydev.com</User>
        <Password>#{JiraSpecHelper::YETI_PASSWORD}</Password>

        <WorkspaceName>Yeti Manual Test Workspace</WorkspaceName>
        <Projects>
            <Project>My Project</Project>
        </Projects>
        <ArtifactType>UserStory</ArtifactType>
        <ExternalIDField>ExternalID</ExternalIDField>
        <CrosslinkUrlField>Affected Customers</CrosslinkUrlField>
    </RallyConnection>

    <JiraConnection>
        <Url>http://bld-intjira60-01:8080/</Url>
        <User>testuser</User>
        <Password>testuser</Password>

        <Project>Automated Corner Cases</Project>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
    </JiraConnection>

    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>            <Other>Summary</Other>      <Direction>BOTH</Direction></Field>
            <Field><Rally>Description</Rally>     <Other>Description</Other>  <Direction>BOTH</Direction></Field>
            <Field><Rally>Schedule State</Rally>  <Other>Status</Other>       <Direction>BOTH</Direction></Field>
        </FieldMapping>
    </Connector>

    <ConnectorRunner>
        <Preview>False</Preview>
        <LogLevel>INFO</LogLevel>
        <Services>
                  UPDATE_RALLYFIELDS_AND_OTHER,
                  COPY_JIRA_TO_RALLY,
                  COPY_RALLY_TO_JIRA,
        </Services>
    </ConnectorRunner>
</Config>
  }


describe "The JIRA Connector Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
    @connection = nil
    @rc = nil
    @connector = nil
  end

  #before :each do
  #  @root = JiraSpecHelper::load_xml(COCO_TEST_CONFIG).root
  #  @rc = RallyConnection.new(@root)
  #  @rc.connect()
  #  @connection = RallyEIF::WRK::JiraConnection.new(@root)
  #  @jira = @connection
  #  @connection.connect()
  #  @connector = Connector.new(@root, @rc, @connection)
  #end

  #after(:each) do
  #  @connection.disconnect() if !@connection.nil?
  #  @rc.disconnect() if !@rc.nil?
  #end

  it "must validate the config" do
    konfab = Konfabulator.new(COCO_TEST_CONFIG)
    konfab.should_not be_nil
  end



end
