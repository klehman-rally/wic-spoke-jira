# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include JiraSpecHelper

describe "The Jira Connection Find Tests" do

  before :all do
    #Set current working dir to yeti root, as ca_agile_central2_jira_connector.rb sees it
    # Dir.chdir(File.join(File.expand_path(File.dirname(__FILE__)), "../../configs"))
  end

  before(:each) do
    @konfab = Konfabulator.new(JiraSpecHelper::JIRA_CONFIG_FILE)
    @jira = RallyEIF::WRK::JiraConnection.new(@konfab.section("JiraConnection"))
    @connection = @jira
    @jira.connect()
  end

  after(:each) do
    @jira.disconnect() if !@jira.nil?
  end


  # 1
  it "should find a known Jira Bug by id" do
    fields = { 'Description' => 'A simple test Bug to be found by Jira Issue ID' }
    issue, key = create_jira_issue(fields)
    found_issue = @jira.find(key)
    found_issue.should_not be_nil
  end

  # 2
  it "should find a known Jira Bug by the external ID" do
    fields = { 'Description' => 'A simple test Bug to be found by Jira external ID (Rally OID)' }
    issue, key  = create_jira_issue(fields)
    external_id = @jira.get_external_id_value(issue)
    found_issue = @jira.find_by_external_id(external_id)
    found_issue.should_not be_nil
  end

  # 3
  it "should raise exception on attempting to find a JIRA issue by id where no such id" do
    lambda { @jira.find('BOGON-4321') }.should raise_error(RecoverableException, /Issue Does Not Exist/)
  end

  # 4
  it "should result in Nil object when attempting to find a JIRA issue by Rally ID where no such Rally ID exists" do
    lambda { @jira.find_by_external_id(9999000111111) }.should raise_error(RecoverableException, /Could not find/)
  end

  # 5
  it "should find new defects" do
    initial_set = @jira.find_new()
    initial_size = initial_set.length

    fields = { 'Summary'     => "The first additional issue after a check for new issues",
               'Description' => 'newly added Bug 1'
    }
    issue, key1 = create_jira_issue(fields, default_external_id=true)
    found_issue = @jira.find(key1)
    found_issue.should_not be_nil

    fields = { 'Summary'     => "The second additional issue after a check for new issues",
               'Description' => 'newly added Bug 2'
    }
    issue, key2 = create_jira_issue(fields, default_external_id=true)
    found_issue = @jira.find(key2)
    found_issue.should_not be_nil

    test_set = @jira.find_new()
    test_size = test_set.length
    test_size.should >= initial_size + 2

    found_defect_one = false
    found_defect_two = false
    test_set.each do |test|
      found_defect_one = true if test.Summary == "The first additional issue after a check for new issues"
      found_defect_two = true if test.Summary == "The second additional issue after a check for new issues"
    end
    found_defect_one.should == true
    found_defect_two.should == true
  end

  # 6
  it "should find updates" do
    # record a reference time of now - 5 seconds
    # create a new Bug with a distinctive summary (and has an external_id value that has a valid form (ie. not -1)
    # issue a call for find_updates(reference_time)
    # the set returned should include the Bug you just created with the distinctive summary text
    ref_time = Time.now.utc - 5
    distinctive_summary = "update finder test " + rand(1000000).to_s
    issue, key = create_jira_issue({'Summary' => distinctive_summary})

    results = @jira.find_updates(ref_time)
##
##    puts results.length
##    results.each do |iss|
##       key = iss["key"]
##       fields = iss["fields"]
##       type = ["issuetype"]["name"]
##       puts "%s %s  summary: %s" % [type, key, @jira.get_value(fields, "summary")]
##    end
##
    targets = results.select { |bug| @jira.get_value(bug, 'Summary') == distinctive_summary }
    targets.length.should == 1
  end

  # 7
  it "should find new issues using an additional CopySelector with operator equals" do
    bug1_priority = "Highest"
    bug2_priority = "Low"
    @jira.copy_selectors << YetiSelector.new("Priority = #{bug2_priority}", "Copy")

    # determine original new bugs in the system to not pollute the length check later on
    before_bugs = @jira.find_new()

    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue1, key1 = create_jira_issue({'Summary'     => "FindWithCS #1 at #{when_time}",
                                      'Description' => 'for finding new issues using an equality CopySelector',
                                      'Priority'    => bug1_priority
                                     }, default_external_id=true)
    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue2, key2 = create_jira_issue({'Summary'     => "FindswithCS #2 at #{when_time}",
                                      'Description' => 'for finding new issues using an equality CopySelector',
                                      'Priority'    => bug2_priority
                                     }, default_external_id=true)

    after_bugs = @jira.find_new()
    after_bugs.length.should == before_bugs.length + 1
  end

  # 8
  it "should find new issues using an additional CopySelector with a != relation" do
    bug1_priority = "Highest"
    bug2_priority = "Low"
    @jira.copy_selectors << YetiSelector.new("Priority != #{bug2_priority}", "Copy")

    # determine original new bugs in the system to not pollute the length check later on
    before_bugs = @jira.find_new()
    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue1, key1 = create_jira_issue({ 'Summary'      => "FINCS #1 at #{when_time}",
                                       'Description'  => 'for finding new issues using a negation CopySelector',
                                       'Priority'     => bug1_priority
                                     },
                                     default_external_id=true)
    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue2, key2 = create_jira_issue({ 'Summary'      => "FINCS #2 at #{when_time}",
                                       'Description'  => 'for finding new issues using a negation CopySelector',
                                       'Priority'     => bug2_priority
                                     },
                                     default_external_id=true)

    after_bugs = @jira.find_new()
    after_bugs.length.should == before_bugs.length + 1
  end

  # 9
  it "should detect the existence a CopySelector using an invalid value" do
    # Use a CopySelector in which 'Priority = BarbaryCoastPirates' is defined (BarbaryCoastPirates is an invalid priority value)
    bug1_priority = "Highest"
    bug2_priority = "High"
    # first obtain an instance of a valid CopySelector
    @jira.copy_selectors << YetiSelector.new("Priority = #{bug2_priority}", "Copy")
    # determine original new bugs in the system to not pollute the length check later on
    before_bugs = @jira.find_new()

    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue1, key1 = create_jira_issue({ 'Summary'      => "FIBCS #1 at #{when_time}",
                                       'Description'  => 'for finding new issues using a bad CopySelector',
                                       'Priority'     => bug1_priority
                                     },
                                     default_external_id=true)
    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue2, key2 = create_jira_issue({ 'Summary'      => "FIBCS #2 at #{when_time}",
                                       'Description'  => 'for finding new issues using a bad CopySelector',
                                       'Priority'     => bug2_priority
                                     },
                                     default_external_id=true)

    # now munge the CopySelector to have an invalid value (which invalidates the entire CopySelector instance)
    @jira.copy_selectors[1].value = 'BarbaryCoastPirates'
    lambda { issue = @jira.find_new() }.should raise_error(UnrecoverableException)
  end

  # 10
  it "should not succeed in finding new bugs when given a CopySelector with an invalid field name" do
    @jira.copy_selectors << YetiSelector.new("BarnDoor = OpeN", "Copy")
    status = @jira.validate()
    status.should == false  # with JIRA REST we *can* obtain an authoritative list of field names for the issue type
    lambda { issues = @jira.find_new() }.should raise_error(UnrecoverableException)
  end

  # 11
  it "should run find_new with a simple CopySelector" do
    summary = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    orig_defects = @jira.find_new()

    fields = {}
    fields['Summary'] = summary + " - find_new with CopySelector should find me"
    fields['Status'] = "To Do"
    defect1 = @jira.create(fields)
    fields['Summary'] = summary + " - find_new with CopySelector should NOT find me"
    fields['Status'] = "Done"
    defect2 = @jira.create(fields)

    new_defects = @jira.find_new()
    new_defects.length.should == orig_defects.length + 1
  end

  # 12
  it "should find defects using multiple CopySelector criteria" do
    # with the use of JIRA_CONFIG_FILE in creating the @jira Connection,
    # there is already a CopySelector of Status != Closed
    # we add two more CopySelectors
    yesterday = Time.now - 86400
    threshold_date = yesterday.strftime('%Y-%m-%d')
    @jira.copy_selectors << YetiSelector.new("Severity = Crash/Data Loss", "Copy")
    @jira.copy_selectors << YetiSelector.new("Created >= #{threshold_date}", "Copy")

    random_part = rand(10000).to_s
    summary = Time.now.strftime("%y%m%d-") + random_part + " - multi selector find_new test"
    orig_defects = @jira.find_new()

    fields = {}
    fields['Summary'] = summary + " -> don't find me"
    defect1 = @jira.create(fields)

    fields['Status'] = "To Do"
    fields['Summary'] = summary + " -> me neither"
    defect2 = @jira.create(fields)

    fields['Severity'] = "Crash/Data Loss"
    fields['Summary'] = summary + " -> but do find me"
    defect3 = @jira.create(fields)

    new_defects = @jira.find_new()
    #puts "Defects matching criteria: #{new_defects.length}"
    new_defects.length.should == orig_defects.length + 1
  end

  # 13
  it "should run find_new with CopySelectors using a standard field and a JIRA field that has to be translated for JQL validity" do
    # with the use of JIRA_CONFIG_FILE in creating the @jira Connection,
    # there is already a CopySelector of Status != Closed
    # we add another CopySelector
    yesterday = Time.now - 86400
    threshold_date = yesterday.strftime('%Y-%m-%d')
    @jira.copy_selectors << YetiSelector.new("Component/s = Starboard Foot", "Copy")

    random_part = rand(10000).to_s
    summary = Time.now.strftime("%y%m%d-") + random_part + " - multi selector translated std field find_new test"
    orig_defects = @jira.find_new()

    fields = {}
    fields['Summary'] = summary + " -> don't find me"
    defect1 = @jira.create(fields)

    fields['Status'] = "In Progress"
    fields['Summary'] = summary + " -> me neither"
    defect2 = @jira.create(fields)

    fields['Component/s'] = "Starboard Foot"
    fields['Summary'] = summary + " -> but do find me"
    defect3 = @jira.create(fields)

    new_defects = @jira.find_new()
    #puts "Defects matching criteria: #{new_defects.length}"
    new_defects.length.should == orig_defects.length + 1
  end

  #14
  it "should handle a Selector field that is valid but not mappable" do
    # with the use of JIRA_CONFIG_FILE in creating the @jira Connection,
    # there is already a CopySelector of Status != Closed
    # we add another CopySelector that uses the CreatedDate field
    yesterday = Time.now - 86400
    threshold_date = yesterday.strftime('%Y-%m-%d')
    @jira.copy_selectors << YetiSelector.new("CreatedDate >= 2014-10-30", "Copy")

    random_part = rand(10000).to_s
    summary = Time.now.strftime("%y%m%d-") + random_part + " - multi selector translated std field find_new test"
    orig_defects = @jira.find_new()

    fields = {}
    fields['Summary'] = summary + " -> please find me based on CreatedDate"
    defect1 = @jira.create(fields)

    new_defects = @jira.find_new()
    #puts "Defects matching criteria: #{new_defects.length}"
    new_defects.length.should == orig_defects.length + 1
  end

  #15
  it "should raise error finding NEW issues when a bad external id field has been configured" do
    @jira.external_id_field = "NO_SUCH_STRIPED_ANIMAL_ID"
    lambda { @jira.find_new() }.should raise_error(UnrecoverableException)
  end

  #16
  it "should raise error finding UPDATED issues when a bad external id field has been configured" do
    @jira.external_id_field = "NO_SUCH_STRIPED_ANIMAL_ID"
    now = Time.now.utc
    lambda { @jira.find_updates(now) }.should raise_error(UnrecoverableException)
  end

  #17
  it "Test Find Updates with future timestamp" do
    # create a new Jira Bug with a distinctive summary (and has an external_id value that has a valid form (ie. not -1)
    # then set a reference timestamp 10 minutes in to the future
    # and issue a call for find_updates(reference_time)
    # the set returned should include the Bug you just created because the connection now defaults
    # to 5 minutes if the timestamp was invalid (aka in the future)
    distinctive_summary = "FUTURAMA BUGSHIELD: " + rand(1000000).to_s
    issue, key = create_jira_issue({ 'Summary' => distinctive_summary })

    ref_time = Time.now.utc + 600
    results = @jira.find_updates(ref_time)
    results.select { |bug| @jira.get_value(bug, 'Summary') == distinctive_summary }.length.should == 1
  end

  #18
  it "should find new with an issue type with a space" do
    jc = JiraSpecHelper::jira_connect(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    distinctive_summary = "New Feature: " + rand(1000000).to_s
    results1 = jc.find_new()
    issue, key = create_issue(jc, { 'Summary' => distinctive_summary })
    #puts issue.inspect
    results2 = jc.find_new()
    results2.length.should > results1.length
  end

  #19
  it "should find updates with an issue type with a space" do
    jc = JiraSpecHelper::jira_connect(JiraSpecHelper::JIRA_NON_BUG_CONFIG_FILE)
    distinctive_summary = "New Feature for updates: " + rand(1000000).to_s
    upd_time = Time.now.utc - 60
    results1 = jc.find_updates(upd_time)
    issue, key = create_issue(jc, { 'Summary' => distinctive_summary, "#{jc.external_id_field.to_s}" => rand(1000000).to_s })
    results2 = jc.find_updates(upd_time)
    results2.length.should > results1.length
  end

  it "find new and updated with selectors of type subset for Status" do
    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<CopySelector>Status != Done</CopySelector>',       "<CopySelector>Status in To Do, In Progress</CopySelector>")
    config.sub!('<UpdateSelector>Priority != High</UpdateSelector>', "<UpdateSelector>Status in To Do,  In Progress</UpdateSelector>")
    jc = JiraSpecHelper::jira_connect(config)
    kierkegaard = "That's how the world ends: to general applause from wits who belive it's a joke "
    summary1 = kierkegaard + rand(1000000).to_s
    summary2 = kierkegaard + rand(1000000).to_s
    issue1, key1 = create_issue(jc, { 'Summary' => summary1})
    results = jc.find_new()
    results.select{|d| d.key == key1}.should_not be_empty
    results.select{|d| d['Status'] == "To Do"}.should_not be_empty
    results.select{|d| d['Status'] == "In Review"}.should be_empty

    upd_time = Time.now.utc - 60
    issue2, key2 = create_issue(jc, { 'Summary' => summary2, "#{jc.external_id_field.to_s}" => rand(1000000).to_s, 'Status' => 'In Progress' })
    results2 = jc.find_updates(upd_time)
    results2.select{|d| d.key == key2}.should_not be_empty
    results2.select{|d| d['Status'] == 'In Review'}.should be_empty
    results2.first['Status'].should == 'In Progress'

    extra_space = "In  Progress"
    config.sub!("<CopySelector>Status in To Do, In Progress</CopySelector>", "<CopySelector>Status in To Do, \"#{extra_space}\"</CopySelector>")
    jc = JiraSpecHelper::jira_connect(config)
    lambda { jc.find_new() }.should raise_error(UnrecoverableException, /The value '#{extra_space}' does not exist for the field 'Status'/)
  end

  it "use CopySelector with !in operator" do
    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<CopySelector>Status != Done</CopySelector>', "<CopySelector>Status !in In Review, Done</CopySelector>")
    jc = JiraSpecHelper::jira_connect(config)
    groucho = "I refuse to join any club that wojld have me as a member "
    summary1 = groucho + rand(1000000).to_s
    summary2 = groucho + rand(1000000).to_s
    issue1, key1 = create_issue(jc, { 'Summary' => summary1})
    issue2, key2 = create_issue(jc, { 'Summary' => summary2, 'Status' => 'Done'})
    results = jc.find_new()
    results.select{|d| d.key == key1}.should_not be_empty
    results.select{|d| d.key == key2}.should be_empty
    results.select{|d| d['Status'] == 'To Do'}.should_not be_empty
    results.select{|d| d['Status'] == 'Done'}.should be_empty
  end

  it "find_new with a range type CopySelector for Created date" do
    low_value  = Time.at(Time.now.to_i - (2 * 86400)).utc.to_s.split(' ').first
    high_value = Time.at(Time.now.to_i + 86401).utc.to_s.split(' ').first #a second passed midnight
    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<CopySelector>Status != Done</CopySelector>', "<CopySelector>created between \"#{low_value}\" and \"#{high_value}\"</CopySelector>")
    jc = JiraSpecHelper::jira_connect(config)

    fairy_tale = "There was a king who loved a humble maiden"
    summary = fairy_tale + rand(1000000).to_s
    issue, key = create_issue(jc, { 'Summary' => summary})
    results = jc.find_new()
    results.select{|d| d.key == key}.should_not be_empty
    results.select{|d| Time.parse(d['Created']) >= Time.parse(low_value)}.should_not be_empty
    results.select{|d| Time.parse(d['Created']) <= Time.parse(high_value)}.should_not be_empty
    results.select{|d| Time.parse(d['Created']) < Time.parse(low_value)}.should be_empty
    results.select{|d| Time.parse(d['Created']) > Time.parse(high_value)}.should be_empty
  end

  it "find new with a range type CopySelector for originalEstimate" do
    low_value  = '2h'
    high_value = '5h'
    out_value  = '6h'
    fairy_tale = "There was a king who loved a humble maiden"
    summary1 = fairy_tale + rand(1000000).to_s
    summary2 = fairy_tale + rand(1000000).to_s
    summary3 = fairy_tale + rand(1000000).to_s

    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<CopySelector>Status != Done</CopySelector>', "<CopySelector>OriginalEstimate between \"#{low_value}\" and \"#{high_value}\"</CopySelector>")
    jc = JiraSpecHelper::jira_connect(config)

    issue1, key1 = create_issue(jc, { 'Summary' => summary1, 'Time Tracking' => {'originalEstimate' => low_value}})
    issue2, key2 = create_issue(jc, { 'Summary' => summary2, 'Time Tracking' => {'originalEstimate' => high_value}})
    issue3, key3 = create_issue(jc, { 'Summary' => summary3, 'Time Tracking' => {'originalEstimate' => out_value}})

    results = jc.find_new()
    results.select{|d| d.key == key1}.should_not be_empty
    results.select{|d| d['Time Tracking']['originalEstimate'] > high_value}.should be_empty
    results.select{|d| d['Time Tracking']['originalEstimate'] >= low_value && d['Time Tracking']['originalEstimate'] <= high_value}.should_not be_empty
  end

  it "use !between operator in CopySelector for Created date" do
    low_value  = Time.at(Time.now.to_i - (5 * 86400)).utc.to_s.split(' ').first
    high_value = Time.at(Time.now.to_i - (3 * 86400)).utc.to_s.split(' ').first
    config = JiraSpecHelper::JIRA_CONFIG_FILE.dup
    config.sub!('<CopySelector>Status != Done</CopySelector>', "<CopySelector>created !between \"#{low_value}\" and \"#{high_value}\"</CopySelector>")
    jc = JiraSpecHelper::jira_connect(config)

    fairy_tale = "There was a king who loved a humble maiden "
    summary = fairy_tale + rand(1000000).to_s
    issue, key = create_issue(jc, { 'Summary' => summary})
    results = jc.find_new()
    results.select{|d| d.key == key}.should_not be_empty
    results.select{|d| Time.parse(d['Created']) >= Time.parse(low_value) && Time.parse(d['Created']) <= Time.parse(high_value)}.should be_empty
  end

  it "should find new issues a CopySelector whose target field contains at least one space" do
    bug1_priority = "Highest"
    bug2_priority = "Low"
    @jira.copy_selectors << YetiSelector.new("Story Points >= 2", "Copy")

    # determine original new bugs in the system to not pollute the length check later on
    before_bugs = @jira.find_new()

    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue1, key1 = create_jira_issue({'Summary'      => "FindWithCS #1 at #{when_time}",
                                      'Description'  => 'for finding new issues using a CopySelector whose relational operator is >=',
                                      'Priority'     => bug1_priority,
                                      'Story Points' => 5
                                     }, default_external_id=true)
    when_time = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    issue2, key2 = create_jira_issue({'Summary'     => "FindswithCS #2 at #{when_time}",
                                      'Description' => 'for finding another new issue using a CopySelector whose relational operator is >=',
                                      'Priority'    => bug2_priority,
                                      'Story Points' => 1
                                     }, default_external_id=true)

    after_bugs = @jira.find_new()
    after_bugs.length.should == before_bugs.length + 1
  end

  it "should find new issues - where one of CopySelector target fields (for !=) has an actual null value" do
    @jira.project = 'JEST'
    @jira.artifact_type = 'Story'
    @jira.copy_selectors << YetiSelector.new("Component/s != 'Starboard Foot'", "Copy")
    # wrt the previous line, we know there are issues where Component/s value is unassigned (ie., null)

    found_stories = @jira.find_new()
    found_stories.length.should > 0

    #found_stories.each{|story| puts "#{story.key}    #{story['Component/s']}"}
    null_field_value_stories = found_stories.select{|story| story.component == nil || story.component.empty?}
    null_field_value_stories.length.should > 0
  end

end
