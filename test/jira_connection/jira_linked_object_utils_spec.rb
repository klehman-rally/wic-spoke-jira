# encoding: UTF-8
# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "Jira Linked Object Utils Module Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
  end

  before(:each) do
    konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @jira = JiraConnection.new(konfab.section("JiraConnection"))
    @connection = @jira
    @jira.connect()
  end

  after(:each) do
    @jira.disconnect() if !@jira.nil?
  end

  it "should set/get remote attachments" do
    # add at least 3 attachments, 1 a text file and 2,3 arg jpeg files
    fields = { 'Description' => 'A simple test bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    file1 = 'attachments/testattachment.txt'
    file2 = 'attachments/earthjello.jpeg'
    file3 = 'attachments/Josef Stalin.jpg'
    text_file = {:filename => file1, :mimetype => 'text/plain', :file_content => File.open(file1, 'rb').read}
    jpeg_file = {:filename => file2, :mimetype => 'image/jpeg', :file_content => File.open(file2, 'rb').read}
    img_file  = {:filename => file3, :mimetype => 'image/jpeg', :file_content => File.open(file3, 'rb').read}
    attachments = [text_file, jpeg_file, img_file]
    @jira.set_attachments(issue, attachments)

    found_issue = @jira.find(key)
    found_issue.should_not be_nil

    attachments = @jira.get_attachments(found_issue)
    attachments.length.should == 3

    earthy = attachments.find { |att_info| att_info.filename == 'earthjello.jpeg'}
    earthy.mimetype.should == 'image/jpeg'
    earthy_content = @jira.read_attachment_content(found_issue, earthy)
    e2 = File.open(file2, 'rb').read
    earthy_content.length.should == e2.length

    commie = attachments.find {|att_info| att_info.filename == "Josef Stalin.jpg"}
    commie.mimetype.should == 'image/jpeg'
    commie_content = @jira.read_attachment_content(found_issue, commie)
    commie_content.length.should == 23659
  end

  it "read attachment" do
    fields = { 'Description' => 'Thankfully a garbage can can protect you' }
    issue, key = create_jira_issue(fields)
    file = 'attachments/testattachment.txt'
    text_file = {:filename => file, :mimetype => 'text/plain', :file_content => File.open(file, 'rb').read}
    attachments = [text_file]
    @jira.set_attachments(issue, attachments)
    found_issue = @jira.find(key)
    found_issue.should_not be_nil
    attachments = @jira.get_attachments(found_issue)
    attachments.length.should == 1

    root = JiraSpecHelper::load_xml(JiraSpecHelper::JIRA_ATTACHMENT_CONFIG_FILE)
    connection = RallyEIF::WRK::JiraConnection.new(root)
    connection.connect()
    attachment_content = connection.read_attachment_content(found_issue, attachments.first)
    attachment_content.should == File.open(file, 'rb').read
  end

  it "should be able to post an attachment of a file having a multibyte character filename" do
    chinese_file_name = 'attachments/屏幕截图.xml'

    File.open(chinese_file_name, 'w') do |f|
      f << "Hello World\n"
    end

    fields = { 'Description' => 'issue with an attachment having a Chinese ideogram filename' }
    issue, key = create_jira_issue(fields)
    file_content = "" and File.open(chinese_file_name, 'r') {|f| file_content = f.read()}
    chinese_file_name_file = {:filename => chinese_file_name, :mimetype => 'application/xml', :file_content => file_content}
    attachments = [chinese_file_name_file]
    @jira.set_attachments(issue, attachments)

    target_issue = @jira.find(key)
    target_issue.should_not be_nil

    attachments = @jira.get_attachments(target_issue)
    attachments.length.should ==1

    chinese_xml = attachments.find { |att_info| att_info.filename == File.basename(chinese_file_name)}
    chinese_xml.should_not be_nil
    chinese_xml.mimetype.should == 'application/xml'
    xml_file_content = @jira.read_attachment_content(target_issue, chinese_xml)
    xml_file_content.gsub(/\r/, '').length.should == file_content.length

    FileUtils.rm chinese_file_name
  end

  it "should set and get remote comments" do
    fields = { 'Description' => 'A simple test bug used as a vehicle for Comments testing' }
    issue, key = create_jira_issue(fields)
    comments = []
    comments.push({:author => "someuser@rallydev.com", 
                   :text   => "All systems are go unless your base are belonging to us in forfeit game maybe you do"
                  })
    @jira.add_comments(issue, comments)

    found_issue = @jira.find(key)
    found_issue.should_not be_nil

    comment_list = @jira.get_comments(found_issue)
    comment_list.length.should == 1
  end

end
