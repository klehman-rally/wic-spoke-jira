# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "JIRA REST connection" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @connection = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
  end

  it "should throw an UnrecoverableException for an invalid JIRA URL" do
    @connection.url = "http://foobar:1111"
    lambda { @connection.connect() }.should raise_error(UnrecoverableException)
  end

  it "should throw an UnrecoverableException for an URL that doesn't specify a valid port" do
    @connection.url = "http://orca-ubujira1"
    lambda { @connection.connect() }.should raise_error(UnrecoverableException)
  end

  it "should throw an UnrecoverableException for an invalid user name" do
    @connection.user = "barockett"
    lambda { @connection.connect() }.should raise_error(UnrecoverableException)
  end

  it "should throw an UnrecoverableException for an invalid password" do
    @connection.password = "barockett"
    lambda { @connection.connect() }.should raise_error(UnrecoverableException)
  end

  it "should connect to JIRA when given correct config values" do
    @connection.connect()
  end

  # it "should detect inadequate JIRA permissions for a non-qualified user" do
  #   #@connection.user     = "ghuser"
  #   #@connection.password = "ghuser"
  #   @connection.user     = "subhuman"
  #   @connection.password = "jiradev"
  #   lambda {@connection.connect()}.should raise_error(StandardError, /JIRA Permissions incorrect for/)
  # end

  it "should detect the existence of the target external_id_field in JIRA when present" do
    @connection.connect()
    @connection.field_exists?(@connection.external_id_field).should == true
  end

  it "should detect the existence of the target AccountID in JIRA when present" do
    config = Konfabulator.new(JiraSpecHelper::ON_DEMAND_JIRA_CONNECTION)
    jira_connection = RallyEIF::WRK::JiraConnection.new(config.section('JiraConnection'))
    lambda{jira_connection.connect()}.should raise_error(RallyEIF::WRK::UnrecoverableException, /Response code .* 403/)
  end

  it "should detect the absence of AccountID in JiraConnection when on-demand JIRA Url is specified" do
    good_jira_conn = JiraSpecHelper::ON_DEMAND_JIRA_CONNECTION
    bad_jira_conn = good_jira_conn.sub(/<AccountID>.*<\/AccountID>/, '')
    config = Konfabulator.new(bad_jira_conn)
    jira_connection = RallyEIF::WRK::JiraConnection.new(config.section('JiraConnection'))
    lambda{jira_connection.connect()}.should raise_error(StandardError, /JiraConnection section of XML config file requires AccountID tag and value/)
  end

  it "should return a false value if the JIRA field does not exist" do
    @connection.connect()
    @connection.field_exists?("foobar_id").should == false
  end

  it "should return a true value if the JIRA field does exist" do
    @connection.connect()
    @connection.field_exists?("Time Tracking").should == true
  end

  it "should return a true value if the JIRA custom field does exist" do
    @connection.connect()
    @connection.field_exists?("RallyItem").should == true
  end

  it "should calculate the relative time to use for find_updates" do
    @connection.connect()
    ref_time1 = Time.now - 300
    rel_minutes = @connection.send(:get_relative_minutes, ref_time1)
    rel_minutes.should >= 5
    ref_time2 = Time.now + 10000
    rel_minutes = @connection.send(:get_relative_minutes, ref_time2)
    rel_minutes.should == TimeFile::DEFAULT_LAST_RUN_MINUTES
  end

  # it "should connect with a proxy" do
  #   proxy_konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE_WITH_PROXY)
  #   proxy_jc = RallyEIF::WRK::JiraConnection.new(proxy_konfab.section("JiraConnection"))
  #   proxy_jc.get_backend_version
  #   lambda {proxy_jc.connect()}.should_not raise_error
  # end

  it "use a valid configuration including JIRA communication timeout values" do
    timeouts_konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_WITH_TIMEOUTS)
    jrc = RallyEIF::WRK::JiraConnection.new(timeouts_konfab.section("JiraConnection"))
    jrc.connect()
    jrc.jira_read_timeout.to_i.should == 44
  end

  it "connect to JIRA using valid timeout values less than the default setting" do
    shorter_timeouts = JiraSpecHelper::JIRA_CONFIG_WITH_TIMEOUTS
    shorter_timeouts.sub!(/<OpenTimeout>\d+<\/OpenTimeout>/, '<OpenTimeout>10</OpenTimeout>')
    shorter_timeouts.sub!(/<ReadTimeout>\d+<\/ReadTimeout>/, '<ReadTimeout>10</ReadTimeout>')
    timeouts_konfab = Konfabulator.new(shorter_timeouts)
    lambda{jrc = RallyEIF::WRK::JiraConnection.new(timeouts_konfab.section("JiraConnection"))}.should_not raise_error
  end

  it "throw an exception if configured timeout values are of the wrong data type" do
    timeouts_konfab = Konfabulator.new(JIRA_CONFIG_WITH_INVALID_TIMEOUTS)
    lambda{RallyEIF::WRK::JiraConnection.new(timeouts_konfab.section("JiraConnection"))
          }.should raise_error(UnrecoverableException, /OpenTimeout .* is not numeric/)
   end

  it "throw an exception if JiraProxy connection attempt times out and writes ERROR message into log file" do
    class JiraConnection
      attr_accessor :jira_open_timeout
    end
    timeouts_konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_WITH_TIMEOUTS)
    jrc = RallyEIF::WRK::JiraConnection.new(timeouts_konfab.section("JiraConnection"))
    jrc.jira_open_timeout = 0.0001
    lambda {jrc.connect()}.should raise_error(UnrecoverableException, /Attempt to open connection to JIRA timed out/)
  end

  it "throw an exception if the Timeout configuration values provided are greater than the maximum allowable value" do
    ridiculous_timeouts = JiraSpecHelper::JIRA_CONFIG_WITH_TIMEOUTS
    ridiculous_timeouts.sub!(/<OpenTimeout>\d+<\/OpenTimeout>/, '<OpenTimeout>4321</OpenTimeout>')
    ridiculous_timeouts.sub!(/<ReadTimeout>\d+<\/ReadTimeout>/, '<ReadTimeout>4321</ReadTimeout>')
    timeouts_konfab = Konfabulator.new(ridiculous_timeouts)
    #timeouts_root = JiraSpecHelper::load_xml(ridiculous_timeouts)

    error_pattern = /OpenTimeout configuration value of 4321 is too large, must be less than 1000/
    lambda{jrc = RallyEIF::WRK::JiraRestConnection.new(timeouts_konfab.section("JiraConnection"))}.should raise_error(UnrecoverableException, error_pattern)
  end

end

