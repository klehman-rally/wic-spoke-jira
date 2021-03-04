# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "Rally-JIRA Connector with Special Character and Rich Text fields" do

  before(:all) do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
    @jira = nil
    @rc = nil
    @connector = nil
  end

  before(:each) do
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

  # Rally and JIRA both accept special characters in any fields
  # Rally's Description is a RTF, while JIRA's is not
  # The HTML tags are maintained during create/update from Rally to JIRA
  # This could make the JIRA Description unreadable if you use the RTF in Rally

  it "should pass the Create-JIRA-to-Rally when Summary includes special chars" do
    # give the summary field text containing special chars
    summary = "Special chars:" + '/!@#$%^&*()-=[]{};:./<>?//'
    issue, key = create_jira_issue({ 'Summary' => summary })
    jira_summary = issue.Summary

    #copy Jira issue (bug) to Rally (defect)
    @connector.copy_to_rally({:artifact => issue})

    #name field in the Rally defect should be identical to jira_summary
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.should_not be_nil
    @rc.get_value(rally_defect, "Name").should == jira_summary
  end

  it "should pass the Create-JIRA-to-Rally when Description includes special chars" do
    #Create a bug in JIRA
    description = "Special chars:" + '/!@#$%^&*()-=[]{};:./<>?//'
    issue, key = create_jira_issue({ 'Description' => description })
    jira_description = issue.Description

    #copy Jira issue (bug) to Rally (defect)
    @connector.copy_to_rally({:artifact => issue})

    #description field in the Rally defect should be identical to jira_description
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.should_not be_nil
    @rc.get_value(rally_defect, "Description").should == jira_description
  end

  it "should pass the Update-JIRA-to-Rally when Summary includes special chars" do
    # Create a bug in JIRA
    # Upon creation, have the summary field with no special chars
    issue, key = create_jira_issue({ 'Summary' => "standard summary fluff text" })
    jira_summary = issue.Summary

    # copy Jira issue (bug) to Rally (defect)
    @connector.copy_to_rally({:artifact => issue})

    # Edit the defect in JIRA, updating the summary to have text containing special chars
    updated_summary = "Special chars:" + '/!@#$%^&*()-=[]{};:./<>?//'
    @jira.update(issue, {'Summary' => updated_summary})
    found_issue = @jira.find(key)
    found_issue.should_not be_nil

    # Now update the corresponding defect in Rally
    @connector.update_rally({:artifact=>found_issue})

    # Check the modified defect in Rally
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.should_not be_nil
    rally_defect.name.should == updated_summary
  end

  it "should pass the Update-JIRA-to-Rally when Description includes special chars" do
    # Create a bug in JIRA
    # Upon creation, have the description field with no special chars
    issue, key = create_jira_issue({ 'Description' => "standard description fluff text" })
    jira_desc = issue.Description

    # copy Jira issue (bug) to Rally (defect)
    @connector.copy_to_rally({:artifact => issue})

    # Edit the defect in JIRA, updating the description to have text containing special chars
    updated_description = 'Special chars appear in this description:' + '/!@#$%^&*()-=[]{};:./<>?//'
    @jira.update(issue, {'Description' => updated_description})
    found_issue = @jira.find(key)
    found_issue.should_not be_nil

    # Now update the corresponding defect in Rally
    @connector.update_rally({:artifact=>found_issue})

    #Check the modified defect in Rally
    rally_defect = @rc.find_by_external_id(key)
    rally_defect.should_not be_nil
    rally_defect.Description.should == updated_description
  end

  it "should pass the Create-Rally-to-JIRA when Name includes special chars" do
    # create a defect in Rally with the name containing special characters
    special_chars_name = "Special chars in the name:" + '/!@#$%^&*()-=[]{};:./<>?//'
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Name' => special_chars_name }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Summary field value matches Rally name field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Summary.should == special_chars_name
  end

  it "should pass the Create-Rally-to-JIRA when Description includes special chars" do
    # create a defect in Rally with the name containing special characters
    special_chars_description = "Special chars in the description:" + '/!@#$%^&*()-=[]{};:./<>?//'
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Description' => special_chars_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Description field value matches Rally description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == special_chars_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Create-Rally-to-JIRA when Description includes HTML bold tag" do
    # create a defect in Rally with the description containing special characters
    #bolded_description = "<bold>Here is the emboldened description</bold>"
    bolded_description = "<b>Here is the emboldened description</b>"
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Description' => bolded_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Description field value matches Rally description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == bolded_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Create-Rally-to-JIRA when Description includes HTML bold/italic/underline tag" do
    # create a defect in Rally with the description containing HTML  bold/italic/underline tags
    htmled_description = "<u><i><b>do this</b></i></u>"
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'description' => htmled_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Description field value matches Rally description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == htmled_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Create-Rally-to-JIRA when Description includes URL link" do
    # create a defect in Rally with the description containing a web link
    description_with_url = '/<a href="http://www.yahoo.com">url to yahoo</a>/'
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Description' => description_with_url }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Description field value matches Rally description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == description_with_url
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Create-Rally-to-JIRA when Description includes image link" do
    # create a defect in Rally with the description containing a web link
    description_with_img_link =  '/<img src="https://rally1.rallydev.com/slm/js/editor/images/image.gif" />/'
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Description' => description_with_img_link }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})

    #find defect in Jira and verify that Description field value matches Rally description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == description_with_img_link
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Update-Rally-to-JIRA when Name includes special chars" do
    # create a defect in Rally with vanilla text for the name field
    vanilla = "vanilla"
    fields = { 'Priority' => "High Attention", 'State' => "Submitted", 'Name' => vanilla }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc

    #find defect in Jira and verify that Summary field value matches Rally name field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Summary.should == vanilla
    jira_bug.Summary.should == rally_defect.name

    #now update the name field in the Rally defect to have special chars in name field
    spec_name = "Special chars:" + '/!@#$%^&*()-=[]{};:./<>?//'
    rally_defect.update( { 'Name' => spec_name })

    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})

    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Summary.should == spec_name
    jira_bug.Summary.should == rally_defect.name
  end

  it "should pass the Update-Rally-to-JIRA when Description includes special chars" do
    #Create defect in Rally with the description having vanilla text
    vanilla_description = "Here is the vanilla description"
    fields = { :priority => "High Attention", :state => "Submitted", :description => vanilla_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_defect.Description.should == vanilla_description
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    jira_bug = @connector.copy_to_other({:artifact => rally_defect})
    jira_bug.Description.should == vanilla_description
    last_connector_run = Time.now.utc

    #update the defect in Rally to have a description containing special chars
    special_description = "Special chars:" + '/!@#$%^&*()-=[]{};:./<>?//'
    rally_defect.update({ :description => special_description })
    sleep(2)
    rally_defect.read()
    rally_defect.Description.should == special_description
    #trigger update of corresponding Jira bug
    jira_bug = @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    jira_bug.RallyID.should == rally_oid
    jira_bug.Description.should == special_description

    #check that the Jira bug description field value is the same as the Rally defect description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == special_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Update-Rally-to-JIRA when Description includes HTML bold tag" do
    #Create defect in Rally with the description having vanilla text
    vanilla_description = "Here is the vanilla wafer description"
    fields = { :priority => "High Attention", :state => "Submitted", :description => vanilla_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc

    #update the defect in Rally to have a description containing the bold tags
    #bolded_description = "<bold>Yet another emboldened description</bold>"
    bolded_description = "<b>Yet another emboldened description</b>"
    rally_defect.update({ :description => bolded_description })

    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})

    #check that the Jira bug description field value is the same as the Rally defect description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    rally_defect.Description.should == bolded_description
    jira_bug.Description.should == bolded_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Update-Rally-to-JIRA when Description includes HTML bold/italic/underline tag" do
    #Create defect in Rally with the description having vanilla text
    vanilla_description = "Here is the plain text description"
    fields = { :priority => "High Attention", :state => "Submitted", :description => vanilla_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    jira_bug = @connector.copy_to_other({:artifact => rally_defect})
    sleep(1)
    jira_bug.Description.should == vanilla_description
    last_connector_run = Time.now.utc

    #update the defect in Rally to have a description containing the tag soup
    tags_description = "<u><i><b>do a lot more of this</b></i></u>"
    rally_defect.update({ :description => tags_description })
    rally_defect.read()
    rally_defect.Description.should == tags_description

    #trigger update of corresponding Jira bug
    jira_bug = @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    sleep(1)
    jira_bug.Description.should == tags_description

    #check that the Jira bug description field value is the same as the Rally defect description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == tags_description
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Update-Rally-to-JIRA when Description includes URL link" do
    #Create defect in Rally with the description having vanilla text
    vanilla_description = "Here is more of just plain text description"
    fields = { :priority => "High Attention", :state => "Submitted", :description => vanilla_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc

    #update the defect in Rally to have a description that contains an URL
    desc_with_url = '/<a href="http://www.yahoo.com">url to yahoo</a>/'
    rally_defect.update({ :description => desc_with_url })
    sleep(1)
    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    sleep(1)
    #check that the Jira bug description field value is the same as the Rally defect description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == desc_with_url
    jira_bug.Description.should == rally_defect.Description
  end

  it "should pass the Update-Rally-to-JIRA when Description includes image link" do
    #Create defect in Rally with the description having vanilla text
    vanilla_description = "Last of the Mohicans"
    fields = { :priority => "High Attention", :state => "Submitted", :description => vanilla_description }
    rally_defect, name = create_rally_artifact(@rc, fields)
    rally_defect.should_not be_nil
    rally_oid = @rc.get_value(rally_defect, "ObjectID")

    #copy defect to Jira
    @connector.copy_to_other({:artifact => rally_defect})
    last_connector_run = Time.now.utc

    #update the defect in Rally to have a description that contains an URL
    desc_with_img_link = '/<img src="https://rally1.rallydev.com/slm/js/editor/images/image.gif" />/'
    rally_defect.update({ :description => desc_with_img_link })
    sleep(1)
    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    sleep(1)
    #check that the Jira bug description field value is the same as the Rally defect description field value
    jira_bug = @jira.find_by_external_id(rally_oid)
    jira_bug.should_not be_nil
    jira_bug.Description.should == desc_with_img_link
    jira_bug.Description.should == rally_defect.Description
  end

end

