# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'spec_helpers/wiki_text_spec_helper'
require 'rspec'

include JiraSpecHelper
include JiraWikiTextSpecHelper
include RallyEIF::WRK::FieldHandlers

jira_wiki_text_field_handler_req = "
    <JiraWikiTextFieldHandler>
      <FieldName>Description</FieldName>
    </JiraWikiTextFieldHandler>"

describe "Rally JiraWikiTextFieldHandler tests" do

  before(:all) do
    @jira = JiraTestConnection.new
    @jira.connect()
    @dfh = JiraWikiTextFieldHandler.new
    @dfh.read_config({'FieldName' => :Description})
    @dfh.connection = @jira
  end

  after :all do
    @jira.disconnect() if !@jira.nil?
  end

  # 1
  it "JiraWikiTextHandler should set field value to Description" do
    @dfh.field_name.should == :Description
  end

  # 2
  it "JiraWikiTextFieldHandler transform_in should return empty for empty input set" do
    artifact = MockJiraArtifact.new("")
    @dfh.transform_out(artifact).should == ""

    artifact = MockJiraArtifact.new("foobar")
    @dfh.transform_out(artifact).should == "<p>foobar</p>"
  end

  # 3
  it "Jira Wiki Text Field Handler transform_in should return html from wiki text" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_text)
    @dfh.transform_out(artifact).should == JWData.html_text
  end

  # 4
  it "Jira Wiki Text Field Handler transform_out should return wiki text from html" do
    @dfh.transform_in(JWData.html_text).should == JWData.jira_wiki_text
  end

  ## transform_in: Rally to Jira
  ## transform_out: Jira to Rally

  # 5
  it "should transform_in headings" do
    @dfh.transform_in(JWData.html_header_text).should == JWData.jira_wiki_header_text
  end

  # 6
  it "should transform_out headings" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_header_text)
    @dfh.transform_out(artifact).should == JWData.html_header_text
  end

  # 7
  it "should transform_in text_effects" do
    @dfh.transform_in(JWData.html_text_effects).should == JWData.jira_wiki_text_effects
  end

  # 8
  it "should transform_out text_effects" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_text_effects)
    @dfh.transform_out(artifact).should == JWData.html_text_effects
  end

  # 9
  it "should transform_in lists" do
    @dfh.transform_in(JWData.html_lists).should == JWData.jira_wiki_lists
  end

  # 10
  it "should transform_out lists" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_lists)
    @dfh.transform_out(artifact).should == JWData.html_lists
  end

  # 11
  it "should transform_in table" do
    @dfh.transform_in(JWData.html_table).should == JWData.jira_wiki_table
  end

  # 12
  it "should transform_out table" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_table)
    @dfh.transform_out(artifact).should == JWData.html_table
  end

  # 13
  it "should transform_in table two" do
    @dfh.transform_in(JWData.html_table_two).should == JWData.jira_wiki_table_two
  end

  # 14
  it "should transform_out table two" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_table_two)
    @dfh.transform_out(artifact).should == JWData.html_table_two
  end

  # 15
  it "should transform_in text breaks" do
    @dfh.transform_in(JWData.html_breaks).should == JWData.jira_text_breaks
  end

  # 16
  it "should transform_out text breaks" do
    artifact = MockJiraArtifact.new(JWData.jira_text_breaks)
    @dfh.transform_out(artifact).should == JWData.html_breaks
  end

  # 17
  it "should transform_in image links" do
    @dfh.transform_in(JWData.html_image_links).should == JWData.jira_wiki_image_links
  end

  # 18
  it "should transform_out image links" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_image_links)
    @dfh.transform_out(artifact).should == JWData.html_image_links
  end

  # 19
  it "should transform_in code to monospaced" do
    @dfh.transform_in(JWData.html_monospaced).should == JWData.jira_wiki_monospaced
  end

  # 20
  it "should transform_out monospaced to code" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_monospaced)
    @dfh.transform_out(artifact).should == JWData.html_monospaced
  end

  # 21
  it "should transform_in blockquote to bq." do
    @dfh.transform_in(JWData.html_blockquote).should == JWData.jira_wiki_blockquote
  end

  # 22
  it "should transform_out bq. to blockquote" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_blockquote)
    @dfh.transform_out(artifact).should == JWData.html_blockquote
  end

  # 23
  it "should transform_in <a href='target'></a> to [target]" do
    @dfh.transform_in(JWData.html_links).should == JWData.jira_wiki_links
  end

  # 24
  it "should transform_out [target] to <a href='target'></a>" do
    artifact = MockJiraArtifact.new(JWData.jira_wiki_links)
    @dfh.transform_out(artifact).should == JWData.html_links
  end

end
