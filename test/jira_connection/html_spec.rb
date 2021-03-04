# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper
include RallyEIF::WRK::FieldHandlers

describe "The Rally/JIRA Connector for HTML description field creation/update Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @rc = RallyConnection.new(@konfab.section("RallyConnection"))
    @rc.connect()
    @jira = JiraConnection.new(@konfab.section("JiraConnection"))
    @connection = @jira
    @jira.connect()
    @connector = Connector.new(@konfab, @rc, @jira)
  end

  
  it "create a JIRA issue with a plain text description and show up in the Rally defect (no field handler)" do
    description = 'Kornhizer Klavichords emit the melliflous sound of elegance'
    issue, key = create_jira_issue({'Summary' => "cotton linty fluff", 'Description' => description})
    issue.Description.should == description
    @connector.copy_to_rally({:artifact => issue}) #copy Jira issue (bug) to Rally (defect)
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Description").should == description
  end

  it "create a JIRA issue with HTML in the description and show up in the Rally defect (with field handler)" do
    @jira.register_field_handler(JiraHTMLFieldHandler.new(:Description))
    description = '{html}<div style="font-family:arial;"><h2>Xavier ' +
          '<b><font color="red">Xylophones</font></b> Xcite X-Men!</h2>' +
          '<p>Announcing the <strong>NEW</strong> and <i>improved</i> plinking instrument.</p>' +
          '</div>{html}'
    issue, key = create_jira_issue({'Summary' => "forlorn unicorns", 'Description' => description})
    issue.Description.should == description
    @connector.copy_to_rally({:artifact => issue}) #copy Jira issue (bug) to Rally (defect)
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Description").should == description.gsub('{html}', '')
  end

  it "create a JIRA issue with no text in the description and show up in the copied Rally Defect (with field handler)" do
    @jira.register_field_handler(JiraHTMLFieldHandler.new(:Description))
    issue, key = create_jira_issue({'Summary' => "used pterodactyl beaks for the taking"})
    issue.Description.should == nil
    @connector.copy_to_rally({:artifact => issue}) #copy Jira issue (bug) to Rally (defect)
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Description").should == nil.to_s
  end


  it "update a JIRA issue with plain text in the description and show up in the Rally defect (no field handler)" do
    issue, key = create_jira_issue({'Summary' => "surfmeister flash", 'Description' => "Todos Santos has big waves"})
    @connector.copy_to_rally({:artifact => issue}) #copy Jira bug to Rally defect
    upd_description = 'The North Shore of Oahu is where the surf-gods rule!'
    fields = {'Description' => upd_description}
    @jira.update(issue, fields)
    issue = @connection.find(key)
    issue.Description.should == upd_description
    @connector.update_rally({:artifact=>issue})
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Description").should == upd_description
  end

  it "update a JIRA issue with HTML text in the description and show up in the Rally defect (with field handler)" do
    @jira.register_field_handler(JiraHTMLFieldHandler.new(:Description))
    upd_desc_text = '<h3>The updated description</h3>' +
                    '<p>Henry had a <strong>handful</strong> of <span style="color:red;">RED</span> ' +
                    '<i> hens </i> on his hands.</p>'
    wrapped_desc_text = "{html}" + upd_desc_text + "{html}"
    issue, key = create_jira_issue({'Summary' => "Malibu at high tide", 'Description' => "Cowabunga Surf Bums"})
    @connector.copy_to_rally({:artifact => issue}) #copy Jira bug to Rally defect
    fields = {'Description' => wrapped_desc_text}
    @jira.update(issue, fields)
    issue = @connection.find(key)
    issue.Description.should == wrapped_desc_text
    @connector.update_rally({:artifact=>issue})
    rally_defect = @rc.find_by_external_id(key)
    @rc.get_value(rally_defect, "Description").should == upd_desc_text
  end

  it "create a Rally defect with plain text in the description and show up in the Jira issue (no field handler)" do
    plain_description = "Crows are solid black"
    fields = { 'Name'        => "Fort Lewis College",
               'Priority'    => "High Attention",
               'State'       => "Submitted",
               'Description' => plain_description }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    @connector.copy_to_other({:artifact => rally_defect})  # copy Rally defect to Jira bug
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Description.should == plain_description
  end

  it "create a Rally defect with HTML text in the description and show up in the Jira issue (with field handler)" do
    @jira.register_field_handler(JiraHTMLFieldHandler.new(:Description))
    desc = '<b>Western Warblers</b> <font color="red">have red feathers</font>'
    wrapped_desc = "{html}" + desc + "{html}"
    fields = { 'Name'        => "Azusa Pacific College",
               'Priority'    => "High Attention",
               'State'       => "Submitted",
               'Description' => desc }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    @connector.copy_to_other({:artifact => rally_defect}) #copy Rally defect to Jira bug
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Description.should == wrapped_desc
  end

  it "update a Rally defect with plain text in the description and show up in the Jira issue (no field handler)" do
    fields = { 'Name'        => "Poudre Vallery Sniffers",
               'Priority'    => "High Attention",
               'State'       => "Submitted",
               'Description' => "Down and out in Beverly Hills"
             }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    @connector.copy_to_other({:artifact => rally_defect}) #copy Rally defect to Jira bug
    last_connector_run = Time.now.utc
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Summary.should == rally_defect.Name
    jira_issue.Description.should == rally_defect.Description
    #now update the description field in the Rally defect to have HTML tags in the text
    sleep(1)
    upd_desc_text = 'The Hollywood back lots are now littered with the careers of many dreamers'
    upd_rally_defect = @rc.update(rally_defect, { 'Description' => upd_desc_text })
    upd_rally_defect.Description.should == upd_desc_text
    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    #find defect in Jira again (post-update_ and verify that Description field value has the {html} bracketing
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Description.should == upd_desc_text
  end

  it "update a Rally defect with HTML text in the description and show up in the Jira issue (with field handler)" do
    @jira.register_field_handler(JiraHTMLFieldHandler.new(:Description))
    fields = { 'Name'        => "Ridgemont High Stoners",
               'Priority'    => "High Attention",
               'State'       => "Submitted",
               'Description' => "Lowenbrau has lost its cachet"
             }
    rally_defect = @rc.create(fields)
    rally_oid = @rc.get_value(rally_defect, "ObjectID")
    @connector.copy_to_other({:artifact => rally_defect}) #copy Rally defect to Jira bug
    last_connector_run = Time.now.utc
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Summary.should == rally_defect.name
    sleep(1)
    #now update the description field in the Rally defect to have HTML tags in the text
    upd_desc_text = '<i>The updated description</i> has swatches of a <strong><font color="purple" size="12">very colorful fabric</font></strong>'
    @rc.update(rally_defect, { 'Description' => upd_desc_text })
    #trigger update of corresponding Jira bug
    @connector.update_other({:artifact => rally_defect, :last_run => last_connector_run})
    #find defect in Jira again (post-update_ and verify that Description field value has the {html} bracketing
    jira_issue = @jira.find_by_external_id(rally_oid)
    jira_issue.Description.should == "{html}" + upd_desc_text + "{html}"
  end

end
