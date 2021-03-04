# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "JIRA Connection Issue Update" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "/../../.."))
  end

  before :each do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @connection = JiraConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @connection.connect()
  end


  it "should successfully update the issue summary (and no other issue fields)" do
    issue, key = create_jira_issue({'Summary' => 'original summary text'})
    initial_state = issue.Status
    upd_summary_text = 'The updated summary text'
    fields = {'Summary' => upd_summary_text}
    upd_issue = @jira.update(issue, fields)
    upd_issue.Summary.should == upd_summary_text
    @jira.get_value(upd_issue, 'Summary').should == upd_summary_text
    upd_issue.Status.should == initial_state
  end

  it "should create/update a Bug with more than just minimal fields populated" do
    issue, key = create_jira_issue({'Summary' => 'The Original Sin'})
    fields = {'Summary'     => 'The updated summary text',
              'Description' => 'The updated description text.',
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
             }
    upd_issue = @jira.update(issue, fields)
    @jira.get_value(upd_issue, 'Summary').should     == fields['Summary']
    @jira.get_value(upd_issue, 'Description').should == fields['Description']
    @jira.get_value(upd_issue, 'Priority').should    == fields['Priority']
    @jira.get_value(upd_issue, 'Reporter').should    == fields['Reporter']
  end

  it "should successfully update the external_id_field" do
    issue, key = create_jira_issue({'Summary' => 'An amorphous pungent ooze'})
    upd_external_id = "77443344"
    @jira.update_external_id_fields(issue, upd_external_id, nil)
    issue = @jira.find(key)
    @jira.get_external_id_value(issue).should == upd_external_id
  end

  it "should raise UnrecoverableException when Priority update value is not a valid value" do
    fields = {'Summary'     => "Abendigo the obstinate",
              'Description' => "Target of attempt to update priority to an invalid value",
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Priority' => "too high!"}
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "raise UnrecoverableException when Priority update value is invalid value in restrictive workflow" do

    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<Project>TST</Project>','<Project>RW</Project>')
    config.sub!('<WorkflowFile>configs/simplified_workflow.xml</WorkflowFile>','<WorkflowFile>configs/jira_workflow.xml</WorkflowFile>')

    @root = JiraSpecHelper::load_xml(config)
    @connection = JiraConnection.new(@root)
    @jira = @connection
    @connection.connect()

    # <Project>RW</Project>

    fields = {'Summary'     => "Daizley school bus transport off in ditch",
              'Description' => "Target of attempt to update resolution to an invalid value",
              'Priority'    => "Low",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Priority'     => 'Awful'}
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "should raise UnrecoverableException when Priority update value type is not valid (an integer)" do
    fields = {'Summary'     => "Benno Schmidt failed profitably",
              'Description' => "Target of attempt to update priority to an invalid value"
             }
    issue, key = create_jira_issue(fields)
    fields = {'Priority' => 10000099}
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "should raise UnrecoverableException when Reporter update value is not valid" do
    fields = {'Summary'     => "Carponza Fiduciary Burglements",
              'Description' => "Target of attempt to update reporter to an invalid value",
              'Priority'    => "High",
              'Reporter'    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = {'Reporter' => 'some_woebegotten_fool_from_outer_skantonia_with_kooties'}
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "change Resolution in a project with simplified workflow" do
    fields = {'Summary'     => "Daizley school bus transport off in ditch",
              'Description' => "Target of attempt to update resolution to an invalid value",
              'Priority'    => "Low",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Status'     => 'Done', 'Resolution' => 'Won\'t Do'}
    updated_issue = @jira.update(issue, fields)
    updated_issue.Status.should == 'Done'
    updated_issue.Resolution.should == "Won't Do"
  end

  it "change Resolution without changing Status simplified workflow" do
    fields = {'Summary'     => "Daizley school bus transport off in ditch",
              'Description' => "Target of attempt to update resolution to an invalid value",
              'Priority'    => "Low",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    updated_issue = @jira.update(issue, {'Resolution' => 'Won\'t Do'})
    updated_issue.Resolution.should == "Won't Do"
  end

  it "change Resolution in a project with restrictive workflow" do
    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<Project>TST</Project>','<Project>RW</Project>')
    config.sub!('<WorkflowFile>configs/simplified_workflow.xml</WorkflowFile>','<WorkflowFile>configs/jira_workflow.xml</WorkflowFile>')

    @konfab = Konfabulator.new(config)
    @connection = JiraConnection.new(@konfab.section("JiraConnection"))
    @jira = @connection
    @connection.connect()

    # <Project>RW</Project>

    fields = {'Summary'     => "Daizley school bus transport off in ditch",
              'Description' => "Target of attempt to update resolution to an invalid value",
              'Priority'    => "Low",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Status'     => 'Closed', 'Resolution' => 'Won\'t Fix'}
    updated_issue = @jira.update(issue, fields)
    updated_issue.Resolution.should == 'Won\'t Fix'
  end

  it "should raise RecoverableException when Resolution update value type is not valid" do
    fields = {'Summary'     => "Daizley school bus transport off in ditch",
              'Description' => "Target of attempt to update resolution to an invalid value",
              'Priority'    => "Low",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Status'     => 'Done', 'Resolution' => 123456789}
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "should raise RecoverableException when Status update value is not valid" do
    fields = {'Summary'     => "Sigrontin school bus transport off in ditch",
              'Description' => "Target of attempt to update status to an invalid value",
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = { 'Status' => "Wishy-Washee" }
    lambda {@jira.update(issue, fields)}.should raise_error(RecoverableException)
  end

  it "should update the status of a JIRA Bug along with setting a valid resolution value" do
    fields = {'Summary'     => "Motorway bandits now qualify for enhanced interrogation techniques",
              'Description' => "Target of attempt to update status to an invalid value",
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = {'Description' => "Gone and forgotten",
              'Status'     => 'Done',
              'Resolution' => "Won't Do"
             }

    upd_issue = @jira.update(issue, fields)
    upd_issue.Description.should == "Gone and forgotten"
    upd_issue.Status.should == JIRA_STATUS_DONE
    upd_issue.Resolution.should == "Won't Do"
  end

  it "should update the status of a JIRA Bug along with the default setting for resolution value" do
    fields = {'Summary'     => "Reggie drained baskets from the corner all day long",
              'Description' => "Three point shooting has been proven beneficial to teams with short players",
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Description' => "Gone and forgotten",
              'Status'      => 'Done'
             }

    upd_issue = @jira.update(issue, fields)
    upd_issue.Description.should == "Gone and forgotten"
    upd_issue.Status.should      == JIRA_STATUS_DONE
    upd_issue.Resolution.should  == "Done"
  end

  it "should update the status of a JIRA Bug to Closed along with a resolution value of Done" do
    fields = {'Summary'     => "Barney drove his snowmobile into the side of the convenience store",
              'Description' => "Boogety Boogety",
              'Priority'    => "Highest",
              'Reporter'    => "devuser"
    }
    issue, key = create_jira_issue(fields)
    fields = {'Status'     => 'Done',
              'Resolution' => "Done"
             }

    upd_issue = @jira.update(issue, fields)
    upd_issue.Status.should     == JIRA_STATUS_DONE
    upd_issue.Resolution.should == "Done"
  end

=begin
  it "should update a JIRA Bug Resolution value without updating the Status in a project where Resolution is on the edit screen." do
    @root = load_xml(JiraSpecHelper::JIRA_RESO_TEST_CONFIG_FILE).root
    @jira = JiraConnection.new(@root)
    @jira.connect()
    fields = {'Summary'     => "Fred cheerfully directed traffic into the sinkhole",
              'Description' => "Tourist buses full of zombies too full for safety regoolations",
              'Priority'    => "Blocker",
              'Reporter'    => "devuser"
    }

    issue, key = create_jira_issue(fields)
    @jira.get_value(issue, 'Resolution').should be_nil

    fields = { 'Resolution' => "Done" }

    upd_issue = @jira.update(issue, fields)
    upd_issue.Resolution.should == "Done"
  end

  # Test will only work when Screens allow resolution to be changed.
  it "should allow update of a JIRA resolution value of Bug in a Resolved state." do
    fields = {:summary     => "Resolved to be Good.",
              :description => "Testing resolution updates to an issue in Resolved state.",
              :priority    => "Blocker",
              :reporter    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = {:status     => 'Resolved',
              :resolution => "Done"
             }
    status = @jira.update(issue, fields)
    upd_issue = @jira.find(key)
    @jira.get_value(upd_issue, :resolution).should == "Done"

    fields = {:resolution => "Won't Fix"}
    status = @jira.update(issue, fields)
    upd_issue = @jira.find(key)
    @jira.get_value(upd_issue, :resolution).should == "Won't Fix"
  end

  it "should update the status of a JIRA bug along with setting a valid resolution value" do
    fields = {:summary     => "Sigrontin school bus transport off in ditch",
              :description => "Target of attempt to update status to an invalid value",
              :priority    => "Blocker",
              :reporter    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = {:description => "Gone and forgotten",
              :status     => 'Resolved',
              :resolution => "Won't Fix"
             }

    status = @jira.update(issue, fields)
    upd_issue = @jira.find(key)
    @jira.get_value(upd_issue, :description).should == "Gone and forgotten"
    @jira.get_value(upd_issue, :status).should == JIRA_STATUS_RESOLVED
    @jira.get_value(upd_issue, :resolution).should == "Won't Fix"
  end

  it "should update the status of a JIRA bug along with the default setting for resolution value" do
    fields = {:summary     => "Reggie drained baskets from the corner all day long",
              :description => "Three point shooting has been proven beneficial to teams with short players",
              :priority    => "Blocker",
              :reporter    => "devuser"
             }
    issue, key = create_jira_issue(fields)
    fields = {:description => "Gone and forgotten",
              :status     => 'Resolved'
             }

    status = @jira.update(issue, fields)
    upd_issue = @jira.find(key)
    @jira.get_value(upd_issue, :description).should == "Gone and forgotten"
    @jira.get_value(upd_issue, :status).should == JIRA_STATUS_RESOLVED
    @jira.get_value(upd_issue, :resolution).should == "Fixed"
  end
=end

end
