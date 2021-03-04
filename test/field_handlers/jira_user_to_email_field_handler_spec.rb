# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'spec_helpers/wiki_text_spec_helper'
require 'rspec'

include JiraSpecHelper
include JiraWikiTextSpecHelper
include RallyEIF::WRK::FieldHandlers

jira_user_to_email_field_handler = "
    <JiraUserToEmailFieldHandler>
      <FieldName>Assignee</FieldName>
    </JiraUserToEmailFieldHandler>"

describe "JiraUserToEmailFieldHandler tests" do

  before(:all) do
    config = JIRA_CONFIG_FILE.dup
    config.sub!(/<OtherUserFieldHandler>.+?<\/OtherUserFieldHandler>/m, "#{jira_user_to_email_field_handler}" )
    konfab = Konfabulator.new(config)
    @jira = JiraConnection.new(konfab.section("JiraConnection"))

    @jira.connect()
    @dfh = JiraUserToEmailFieldHandler.new
    fh_info = konfab.section("Connector").getItem("OtherFieldHandlers").first  # we know there is only 1 field handler here
    @dfh.read_config(fh_info[1])
    @dfh.connection = @jira
  end

  after :all do
    @jira.disconnect() if !@jira.nil?
  end

  it "handle a JIRA user valued field being translated to a Agile Central user via the field handler" do
    results = @jira.find_new()
    first_stranger_to_marry = results.select{|b| b['Assignee'] == 'devuser'}.first
    @dfh.transform_out(first_stranger_to_marry).should == 'nmusaelian@rallydev.com'
  end

  it "handle an Agile Central user valued field being translated to a JIRA user via the field handler" do
    @dfh.transform_in('yeti@rallydev.com').should ==  'yeti'
  end

end
