# Copyright 2001-2018 CA Technologies. All Rights Reserved.
require 'date'
require 'time'
require 'pp'
require 'rallyeif-wrk'
require 'rally_jest'

require 'rallyeif/jira/utils/jira_workflow_reader'
require 'rallyeif/jira/jira_connection/jira_workflow'
require 'rallyeif/jira/jira_connection/jira_linked_object_utils'
require 'rallyeif/jira/utils/jira_xsd'

module RallyEIF
  module WRK

    class JiraConnection < RallyEIF::WRK::Connection

      include JiraWorkflow

      #TODO - Decide what number to pick for MAX_NUM_RESULTS
      MAX_NUM_RESULTS = 9999
      JIRA_CLOSED_STATUS = 'Closed'

      #JIRA permissions required to run the connector
      @@on_prem_required_permissions = ['BROWSE', 'CREATE_ISSUE', 'EDIT_ISSUE', 'SCHEDULE_ISSUE', 'ASSIGN_ISSUE',
                                        'ASSIGNABLE_USER', 'RESOLVE_ISSUE', 'CLOSE_ISSUE', 'MODIFY_REPORTER',
                                        'COMMENT_ISSUE', 'CREATE_ATTACHMENT'
      ]
      @@on_demand_required_permissions = [
          'BROWSE_PROJECTS', 'CREATE_ISSUES', 'EDIT_ISSUES', 'SCHEDULE_ISSUES', 'ASSIGN_ISSUES',
          'ASSIGNABLE_USER', 'RESOLVE_ISSUES', 'CLOSE_ISSUES', 'MODIFY_REPORTER',
          'ADD_COMMENTS', 'CREATE_ATTACHMENTS', 'TRANSITION_ISSUES'
      ]

      @@on_demand_other_permissions = [
          'SYSTEM_ADMIN',
          'ADMINISTER',
          'ADMINISTER_PROJECTS',
          'CREATE_SHARED_OBJECTS',
          'BULK_CHANGE',
          'WORK_ON_ISSUES',
          'MOVE_ISSUES',
          'LINK_ISSUES',
          'DELETE_ISSUES',
          'DELETE_OWN_COMMENTS',
          'DELETE_ALL_COMMENTS',
          'EDIT_OWN_COMMENTS',
          'EDIT_ALL_COMMENTS',
          'EDIT_OWN_WORKLOGS',
          'EDIT_ALL_WORKLOGS',
          'DELETE_OWN_WORKLOGS',
          'DELETE_ALL_WORKLOGS',
          'DELETE_ALL_ATTACHMENTS',
          'DELETE_OWN_ATTACHMENTS',
          'MANAGE_WATCHERS',
          'VIEW_READONLY_WORKFLOW',
          'VIEW_VOTERS_AND_WATCHERS',
          'SET_ISSUE_SECURITY',
          'MANAGE_GROUP_FILTER_SUBSCRIPTIONS',
          'VIEW_DEV_TOOLS',
          'USER_PICKER',
          'USE'
      ]

      #These accessors are used only by the RSpec tests
      attr_accessor :url
      attr_accessor :account_id
      attr_accessor :project
      attr_reader :jira_proxy
      attr_reader :jira_version
      attr_reader :workflow
      attr_reader :issue_types
      attr_reader :jira_open_timeout
      attr_reader :jira_read_timeout

      def initialize(config=nil)
        super()
        @jira_open_timeout = nil
        @jira_read_timeout = nil
        read_config(config) if !config.nil?
        @jira_version = "unknown version"
        @user_cache = nil
      end

      def name()
        return "JIRA"
      end

      def self.version_message()
        version_info = "#{RallyEIF::WRK::Jira::Version}-#{RallyEIF::WRK::Jira::Version.detail}"
        return "JiraConnection version: #{version_info} using rally_jest gem version #{RallyJest::VERSION}"
      end

      def version
        RallyEIF::WRK::Jira::Version
      end

      def get_backend_version()
        return "%s %s" % [name, @jira_version]
      end

      def read_config(config)
        super(config)
        @url        = config.getItem("Url")
        @account_id = config.getItem("AccountID")
        @project    = config.getItem("Project")
        @id_field   = :key if @id_field.nil?
        @workflow_file = config.getItem("WorkflowFile")
        @workflow_file = 'jira_workflow.xml' if @workflow_file.nil?
        @workflow = RallyEIF::WRK::Utils::JiraWorkflowReader.read_workflow_file(Dir.pwd + '/' + @workflow_file)
        if @workflow.nil?
          raise UnrecoverableException.new("Could not read workflow from #{@workflow_file}", self)
        end
        # de-symbolize the identity related field names,
        # RallyJest requires all field name references be a JIRA DisplayName String, so we may as well get that done here...
        @id_field          =          @id_field.to_s
        @external_id_field = @external_id_field.to_s
        @end_user_id_field = @end_user_id_field.to_s unless @end_user_id_field.nil?
        @external_end_user_id_field = @external_end_user_id_field.to_s unless @external_end_user_id_field.nil?
        @external_item_link_field   = @external_item_link_field.to_s   unless @external_item_link_field.nil?

        # pick up any optional configuration for open connection and read connection timeouts
        @jira_open_timeout = config.getItem("OpenTimeout", false)
        @jira_read_timeout = config.getItem("ReadTimeout", false)
        if @jira_open_timeout
          if @jira_open_timeout !~ /^\d+$/
            problem = "OpenTimeout configuration value of #{@jira_open_timeout} is not numeric, must be a whole number"
            raise raise UnrecoverableException.new(problem, self)
          end
        end
        if @jira_read_timeout
          if @jira_read_timeout !~ /^\d+$/
            problem = "OpenTimeout configuration value of #{@jira_read_timeout} is not numeric, must be a whole number"
            raise raise UnrecoverableException.new(problem, self)
          end
        end
        @jira_open_timeout = @jira_open_timeout.to_i if @jira_open_timeout
        @jira_read_timeout = @jira_read_timeout.to_i if @jira_read_timeout
        if @jira_open_timeout and @jira_open_timeout > 0 and @jira_open_timeout > 999
          problem = "OpenTimeout configuration value of #{@jira_open_timeout} is too large, must be less than 1000"
          raise UnrecoverableException.new(problem, self)
        end
        if @jira_read_timeout and @jira_read_timeout > 0 and @jira_read_timeout > 999
          problem = "ReadTimeout configuration value of #{@jira_read_timeout} is too large, must be less than 1000"
          raise UnrecoverableException.new(problem, self)
        end
      end

      def connect()
        jest_config = {:url => @url, :user => @user, :password => @password, :project => @project, :logger => RallyLogger}
        jest_config[:open_timeout] = @jira_open_timeout if @jira_open_timeout and @jira_open_timeout > 0
        jest_config[:read_timeout] = @jira_read_timeout if @jira_read_timeout and @jira_read_timeout > 0

        if @url =~ /\.atlassian\.net/i  # is url for Jira OnDemand?
          if @account_id.nil? || @account_id.empty?
            raise StandardError, "When connecting to Jira OnDemand,  JiraConnection section of XML config file requires AccountID tag and value"
          end
          @on_demand = true
          jest_config[:accountId] = @account_id
        end

        RallyLogger.info(self, "Connecting to JIRA at #{@url}")
        if @proxy_url
          jest_config[:proxy_url]       = @proxy_url
          jest_config[:proxy_user]      = @proxy_user     if @proxy_user
          jest_config[:proxy_password]  = @proxy_password if @proxy_password
        end
        @validator.setup_jira({:project_key => @project}) if @validator

        begin
          @jira_proxy = RallyJest::JiraProxy.new(jest_config)
          RallyLogger.info(self, "Using RallyJest version #{RallyJest::VERSION}")
        rescue Faraday::Error::TimeoutError => ex
          raise UnrecoverableException.new("Attempt to open connection to JIRA timed out", self)
        rescue Exception => ex
          RallyLogger.error(self, "Could not log in to JIRA")
          raise UnrecoverableException.copy(ex, self)
        end

        @jira_version = @jira_proxy.getServerInfo().version
        if not appropriate_jira_version(@jira_version, :min_major => 5, :min_minor => 2)
          raise UnrecoverableException.new("JIRA version needs to be 5.2.x or better, current version is #{@jira_version}", self)
        end

        RallyLogger.info(self, "Connected to JIRA at #{@url}, (version %s)" % @jira_version)
        required_permissions = @@on_prem_required_permissions
        required_permissions = @@on_demand_required_permissions if @on_demand
        user_permissions = @jira_proxy.getPermissions(@project)

        system_error, config_error = identify_permission_mismatch(required_permissions, user_permissions)
        if not system_error.empty?
          problem_description = "JIRA Missing permission status for "
          raise UnrecoverableException.new(problem_description + system_error.join(", "), self)
        end
        if not config_error.empty?
          problem_description = "JIRA Permissions incorrect for "
          raise UnrecoverableException.new(problem_description + config_error.join(", "), self)
        end

        @validator.url_user_and_password = "#{RallyEIF::WRK::Validator::Connection::IS_CORRECT}" if @validator
        validate_project()

        @issue_types, issue_type_id_map = @jira_proxy.getIssueTypes()
        RallyLogger.debug(self, "Collected JIRA issue types: #{@issue_types.join(", ")}")
        # turn the @artifact_type symbol from read_config into a String that matches what we have in @issue_types
        jira_issue_type = @issue_types.find {|issue_type_name| issue_type_name.downcase == @artifact_type.to_s.downcase}
        if not jira_issue_type
          unrecognized_type = "artifact type specified |#{@artifact_type}| is not in list of recognized JIRA issue types"
          raise UnrecoverableException.new(unrecognized_type, self)
        end
        @artifact_type = jira_issue_type
        RallyLogger.info(self, "JIRA connection issue type: |#{@artifact_type}|")
        return true
      end

      private
      def appropriate_jira_version(version, args = {})
        # The JIRA version must be 5.2.x or better (ie, 5.2, 6.0, 7.3, etc.)
        major, minor, point = version.split('.').collect {|n| n.to_i}
        min_major = args[:min_major]
        min_minor = args[:min_minor]
        if major > min_major
          return true
        end
        if (major == min_major && minor >= min_minor)
          return true
        end
        return false
      end


      public
      def validate_project()
        if not @project or @project.nil? or @project.empty?
          raise UnrecoverableException.new("A valid Jira project must be specified", self)
        end
        accessible_projects = @jira_proxy.getProjects()
        if not accessible_projects.keys.include?(@project) and not accessible_projects.values.include?(@project)
          problem = "Jira project '%s' either does not exist or is not accessible with the credentials provided" % @project
          raise UnrecoverableException.new(problem, self)
        end
        if accessible_projects.values.include?(@project)  # config names the project name rather than the Jira project key
          proj_key = accessible_projects.find { |key, value| value == @project }.first
          alert = "Using project key '%s' associated with the project name you specified: '%s'" % [proj_key, @project]
          RallyLogger.info(self, alert)
          @project = proj_key
        end
        @validator.project_key = "#{@project} #{RallyEIF::WRK::Validator::Connection::IS_CORRECT}" if @validator
        RallyLogger.info(self, "Confirmed that Jira project #{@project} is accessible")
      end

      def disconnect()
        RallyLogger.info(self, "Disconnected from JIRA")
      end

      def valid_artifacts()
        return @issue_types
      end

      private

      def create_internal(int_work_item)
        # Note: capture the Status and Resolution values in int_work_item
        #       if they exist, then drop them from the int_work_item Hash
        #TODO:  Ultimately, replace usage of status_key and resolution_key assignments
        #       and look for int_work_item['Status'] and int_work_item['Resolution'] directly
        status_key = int_work_item.keys.find { |x| x.to_s.downcase == 'status'}
        desired_status = nil
        desired_status = int_work_item[status_key]  if status_key
        int_work_item.delete(status_key)            if status_key

        resolution_key = int_work_item.keys.find { |x| x.to_s.downcase == 'resolution'}
        resolution = nil
        resolution = int_work_item[resolution_key] if resolution_key
        int_work_item.delete(resolution_key)       if resolution_key

        created_key = int_work_item.keys.find {|x| x.to_s.downcase == 'created'}
        if created_key
          int_work_item.delete(created_key)
          RallyLogger.warning(self, "Jira #{created_key} is not a user settable field, please adjust your config to eliminate this warning")
        end

        updated_key = int_work_item.keys.find {|x| x.to_s.downcase == 'updated'}
        if updated_key
          int_work_item.delete(updated_key)
          RallyLogger.warning(self, "Jira #{updated_key} is not a user settable field, please adjust your config to eliminate this warning")
        end

        # Convert any key in int_work_name that is a Symbol to a String

        # Convert any key in int_work_name that is a Symbol to a String
        wih = {} and int_work_item.each {|field_name, value| wih[field_name.to_s] = value }
        int_work_item = wih

        begin
          created_issue_key = @jira_proxy.createIssue(@project, @artifact_type, int_work_item)
        rescue StandardError => ex
          ## this is the area where we are changing from Unrecoverable to Recoverable.  Review with David
          raise RecoverableException.new("Unable to create new JIRA #{@artifact_type}, #{ex.message}", self)
        end
        begin
          issue = @jira_proxy.getIssue(created_issue_key)
        rescue StandardError => ex
          problem = "Unable to retrieve newly created JIRA #{@artifact_type} #{created_issue_key}, #{ex.message}"
          raise UnrecoverableException.new(problem, self)
        end
        ##
        #    puts "just created a JIRA issue: #{issue.key} with status #{issue.Status}"
        ##

        if status_key && ['resolved', 'closed'].include?(desired_status.downcase)
          if resolution_key
            RallyLogger.debug(self, " Resolution name: |#{resolution}|")
            int_work_item['Resolution'] = resolution  # pack it back in now
          end
        end

        if !desired_status.nil?
##
#      puts "will attempt to update_status of #{@artifact_type} #{created_issue_key} from |#{issue.Status}| to |#{desired_status}|"
##
          issue = update_status(created_issue_key, issue, int_work_item, desired_status, issue.Status)
##
#     puts "updated_issue: #{issue.inspect}"
##
        end

        # check issue against int_work_item to ensure that
        # the field data values that got created are what were intended
        if !desired_status.nil? && issue['Status'] != desired_status
          message = "Issue creation resulted in an issue with a Status value that does not match the intended value of: #{desired_status}"
          RallyLogger.error(self, message)  #note this doesn't raise to prevent duplicates from being created in Jira
        end

        correct, diffs = checkResultAgainstIntent(int_work_item, issue)
        if not correct
          message = "Issue creation resulted in an issue with missing fields or with non-intended field values:\n" + diffs.join("\n")
          RallyLogger.error(self, message)  #note this doesn't raise to prevent duplicates from being created in Jira
        end

        return issue
      end

      def checkResultAgainstIntent(intent, issue)
        # intent  - a Hash with field name keys mapped to a value to be set in a new issue
        # issue   - a RallyJest::JiraIssue instance returned from @jira_proxy.getIssue(created_issue_key) call

        correct = true  # prime the value, be optimistic
        diffs   = []

        for field_name in intent.keys do
          next if ['key', 'issuetype'].include?(field_name)
          field_name = 'project_key' if field_name == 'Project'

          actual_value = get_value(issue, field_name)
          if actual_value.to_s != intent[field_name].to_s
            fs = @jira_proxy.fieldSchema(@project, @artifact_type, field_name)
            if fs.structure == 'array'
              next if equivalent_array(issue[field_name], intent[field_name])
            end
            next if fs.data_type == 'datetime'
            #In the case of Description empty came back as nil where intent was "", but essentially they are equivalent
            next if actual_value.to_s.empty? && intent[field_name].to_s.empty?

            correct = false
            diffs << "Actual #{field_name} value: #{actual_value} not equal to intended value: #{intent[field_name]}."
          end
        end
        return correct, diffs
      end

      private
      def equivalent_array(actual, intent)
        actual_items = actual.split(/, ?/)
        intent_items = intent.split(/, ?/)
        all_as_in_i = actual_items.select { |aval| intent_items.include?(aval) }.length == actual_items.length
        all_is_in_a = intent_items.select { |ival| actual_items.include?(ival) }.length == intent_items.length
        return all_as_in_i && all_is_in_a
      end

      def normalize_datetime(field_value)
        #  /(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})\.(\d{3})((\+|-)\d{4,})$/
        if field_value =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(\+|-)\d{4,}$/
          offset = field_value[-5..-1]
          parts  = field_value.split('T')
          dt     = parts.first
          tmoffs = parts.last
          tm_parts = tmoffs.split('.')
          tm     = tm_parts.first
          millis = tm_parts.last[0..2]
          yr,mn,day = dt.split('-')
          hh,mm,ss  = tm.split(':')
          tm_offset = offset[0..2] + ":" + offset[3..4]
          fv_time = Time.new(yr.to_i, mn.to_i, day.to_i, hh.to_i, mm.to_i, ss.to_i, tm_offset)
          field_value = fv_time.utc.iso8601.sub('Z', ".#{millis}Z")
        end
        field_value
      end


      public
      def has_changed?(issue, int_work_item)
        int_work_item.each do |field_symbol, value|
          field_name = field_symbol.to_s
          field_value = get_value(issue, field_name)

          if !['status', 'priority', 'severity', 'resolution'].include?(field_name.downcase)
            begin
              fs = @jira_proxy.fieldSchema(@project, @artifact_type, field_name)
              field_value = normalize_datetime(field_value) if fs.data_type == 'datetime'
            rescue => ex
            end
          end
          return true if value != field_value
        end
        RallyLogger.debug(self, "Skipped update for #{get_id_value(issue)} since no fields changed.")
        return false
      end

      def update_internal(issue, int_work_item)
        created_key = int_work_item.keys.find {|x| x.to_s.downcase == 'created'}
        if created_key
          int_work_item.delete(created_key)
          RallyLogger.warning(self, "Jira #{created_key} is not a user settable field, please adjust your config to eliminate this warning")
        end

        updated_key = int_work_item.keys.find {|x| x.to_s.downcase == 'updated'}
        if updated_key
          int_work_item.delete(updated_key)
          RallyLogger.warning(self, "Jira #{updated_key} is not a user settable field, please adjust your config to eliminate this warning")
        end

        # Convert any key in int_work_name that is a Symbol to a String
        wih = {} and int_work_item.each {|field_name, value| wih[field_name.to_s] = value }
        int_work_item = wih
        RallyLogger.debug(self, "int_work_item: #{int_work_item}")
        # If there isn't any status change requested in the int_work_item, just do the update and return
        current_status = issue.Status
        status_key = int_work_item.keys.find { |x| x.downcase == :status or x.downcase == 'status'}
        desired_status = status_key ? int_work_item[status_key] : nil
        resolution_key = int_work_item.keys.find { |x| x.downcase == :resolution or x.downcase == 'resolution'}

        begin
          updated_issue = attempt_update(issue, int_work_item)
          updated_issue = update_status(issue.key, issue, int_work_item, desired_status, current_status) # updating status alone
          if updated_issue
            mismatches = int_work_item.select{|key, value| updated_issue[key] != value}
            return updated_issue if mismatches.empty?
          end
        rescue => ex    # try inverting the operations, which will work if this is a restrictive workflow and the status change is to come out of the "final" state
          begin
            updated_issue = update_status(issue.key, issue, int_work_item, desired_status, current_status)
            updated_issue = attempt_update(issue, int_work_item)
            return updated_issue
          rescue => ex
            raise if ex.message =~ /Target status .+ is not (present|defined)/
            raise if ex.message =~ /No transition to JIRA status .+ found for current JIRA status/
            raise RecoverableException.new("Unable to successfully update the issue #{issue.key}, #{ex.message}", self)
          end
        end

        begin
          # attempt to update this issue on the assumption that the workflow is non-restrictive
          #strip out Resolution and save the value
          resolution = nil
          if resolution_key
            resolution = int_work_item[resolution_key]
            int_work_item.delete(resolution_key)
          end
          int_work_item.each_pair{|field_name, value| updated_issue[field_name] = value}
          updated_issue = update_status(issue.key, updated_issue, int_work_item, desired_status, current_status)  # with the Resolution value stripped out
          if resolution
            updated_issue.Resolution = resolution
            if @jira_proxy.updateIssue(updated_issue)
              updated_issue = @jira_proxy.getIssue(updated_issue.key)
            end
          end
        rescue => ex
          raise RecoverableException.new("Unable to completely update the issue #{issue.key}, #{ex.message}", self)
        end

        return updated_issue
      end

      #this should catch any issues that might be closed and not writable
      def pre_copy(artifact)
        begin
          fields = {}
          fields[@external_id_field] = "-1"
          attempt_update(artifact, fields)
        rescue Exception => ex
          RallyLogger.error(self, "#{artifact.key} appears to be in a Closed state or not changeable in your Jira workflow.")
          return false
        end
        return true
      end

      def attempt_update(issue, int_work_item)
        return issue if int_work_item.empty?

        for field, value in int_work_item.each_pair do
          issue[field] = value if field != 'Status' && field != 'Resolution'
        end

        begin
          @jira_proxy.updateIssue(issue)
        rescue => ex
          backtrace  = ex.backtrace.join("\n")
          RallyLogger.error(self, "Attempt to update issue #{issue.key} failed, #{ex.message}")
          RallyLogger.error(self, "Fields supplied to attempt_update: #{int_work_item.inspect}")
          RallyLogger.error(self, backtrace)
          raise UnrecoverableException.new("Unable to update issue #{issue.key}, #{ex.message}", self)
        end

        updated_issue = @jira_proxy.getIssue(issue.key)
        return updated_issue
      end

      def update_status(issue_key, issue, int_work_item, desired_status, current_status=nil)
##
#    puts " in call to update_status(issue_key=|#{issue_key}|, issue=#{issue}, int_work_item=#{int_work_item}, desired_status=|#{desired_status}|)"
##
        return issue if desired_status.nil? || desired_status == current_status
##
#   puts " current issue.Status = |#{issue.Status}|"
##
        updated_issue  = issue

        if not @workflow['Step'].has_key?(desired_status)
          problem = "Target status |#{desired_status}| is not present in #{@workflow_file}"
          raise RecoverableException.new(problem, self)
        end

        if @workflow['Step'][desired_status].nil?
          problem = "Target status #{desired_status} is not defined in #{@workflow_file}"
          raise RecoverableException.new(problem, self)
        end

        transitions = @workflow['Step'][desired_status]['Transition']
        if transitions.nil? || !transitions.has_key?(current_status)
          problem = "No transition to JIRA status |#{desired_status}| found for current JIRA status |#{current_status}| for #{artifact_type} #{issue_key}"
          raise RecoverableException.new(problem, self)
        end

        actions = transitions[current_status]['Action']
        updated_issue = execute_actions(issue, actions, int_work_item)
        return updated_issue
      end

      private
      #  def get_custom_value(issue, field_symbol)
      #    value = @jira_proxy.get_custom_value(issue, field_symbol)
      #    if field_symbol.to_s.downcase == @external_id_field.to_s.downcase
      #      value = value.to_i.to_s
      #    end
      #    return value
      #  end

      def identify_permission_mismatch(required, actual)
        missing_items  = []
        no_permissions = []
        required.each do |item|
          if not actual.has_key?(item)
            missing_items << item
          else
            if actual[item]["havePermission"] == false
              no_permissions << actual[item]["name"]
            end
          end
        end
        return [missing_items, no_permissions]
      end

      def get_relative_minutes(ref_time)
        calc_time = ((Time.now.utc - ref_time.utc) / 60).ceil.to_i
        if calc_time <= 0
          RallyLogger.debug(self, "Calculated delta time from last run is less than 0: #{calc_time}, ref time was #{ref_time}")
          calc_time = TimeFile::DEFAULT_LAST_RUN_MINUTES
        end
        return calc_time
      end

      public

      def get_value(issue, field_name)
        return issue.id  if field_name.to_s.downcase == 'id'
        return issue.key if field_name.to_s.downcase == 'key'
##
#   puts "   get_value(#{issue.key}, |#{field_name}|)    field_name is a #{field_name.class.name}"
##
#begin
#    value = issue[field_name]
#rescue => ex
#    value = nil
##    known_fields = issue.attribute_values().keys
#    puts "   unrecognized field name: |#{field_name}|   here are the known field names..."
#    for known_field in issue.attribute_values().keys
#      puts "    |#{known_field}|"
#    end
#end
        value = issue[field_name.to_s]
        if field_name.to_s.downcase == @external_id_field.to_s.downcase
          value = value.to_i.to_s if not value.nil?
        end
##
#  puts "          value: |#{value}|"
##
        return value
      end

      def get_external_id_value(issue)
        value = get_value(issue, @external_id_field)
        return value if value.nil?
        return value.to_i.to_s
      end

      def update_external_id_fields(issue, external_id, end_user_id=nil, item_link=nil)
        # Return the issue after updating the external_id (and end_user_id and item_link if provided)
        fields = {}
        fields[@external_id_field]          = external_id if !@external_id_field.nil?
        fields[@external_end_user_id_field] = end_user_id if !@external_end_user_id_field.nil?
        fields[@external_item_link_field]   = item_link   if !@external_item_link_field.nil? && !item_link.nil?
        if fields.length > 0
          issue = update(issue, fields)
        end
        return issue
      end

      def get_object_link(issue)
        jira_key = get_id_value(issue)
        return '<a href="%s/browse/%s">%s</a>' % [@url, jira_key, jira_key]
      end

      # artifact is coming to JiraRestConnection
      # Link should be an A HREF.
      # Link needs to be a URL without A HREF for Jira
      def normalize_link(link)
        link =~ /<a href="(.*)">.*<\/a>/i
        $1 || link # returns url if nil returns original link
      end

      def field_exists?(field_name)
        return @jira_proxy.fieldExists?(@project, @artifact_type, field_name)
      end

      def find_new()
        #query = %'type="#{@artifact_type}" and project = "#{@project}" and "#{@external_id_field}" = -1'
        #cs_criteria = ""

        specific_issue_type = "type=\"#{@artifact_type}\""
        project_match       = "project = \"#{@project}\""
        unmatched_issue     = "\"#{@external_id_field}\" = -1"
        if @on_demand
          unmatched_issue   = "(\"#{@external_id_field}\" is null or \"#{@external_id_field}\" = -1)"
        end
        criteria = [specific_issue_type, project_match, unmatched_issue]

        if @copy_selectors && !@copy_selectors.empty?
          @copy_selectors.each do |cs|
            cs_criteria = construct_selector_syntax(cs)
            criteria << cs_criteria
          end
        end

        #     field_name     = cs.field
        #     selector_value = cs.value
        #     #quote the field_name and/or the selector_value if it contains a space,
        #     #  (assumes the field is a String field in this case)
        #     field_name     = "\"#{field_name}\""     if (field_name     =~ / /)
        #     selector_value = "\"#{selector_value}\"" if (selector_value =~ / /)
        #     cs_criteria += " and #{field_name} #{cs.relation} #{selector_value}"
        #   end
        #   query += cs_criteria
        # end
        complete_query = criteria.join(" AND ")

        RallyLogger.info(self, "find_new query: #{complete_query}")

        issues = []
        begin
          issues = @jira_proxy.getIssuesWithJql(complete_query, nil, 0, MAX_NUM_RESULTS)
        rescue Exception => ex
          RallyLogger.error(self, "Trying to find_new via query: \'#{complete_query}\' resulted in #{ex.class}")
          raise UnrecoverableException.copy(ex, self)
        end

        if issues.nil? || issues.empty?
          RallyLogger.info(self, "Found 0 new issues in JIRA")
          return []
        end

        RallyLogger.info(self, "Found #{issues.length} new issues in JIRA")
        return issues
      end

      def quotify(value)
        #result = value.class == String && value.count(' ') > 0  && value.first != '"' && value.first != "'"? '"%s"' % [value] : value
        #returns undefined method `first' for "\"To Do\"":String

        result = value.class == String && value.count(' ') > 0  && value[0] != '"' && value[0] != "'"? '"%s"' % [value] : value
        result
      end

      def construct_selector_syntax(selector)
        field, relation, value = selector.field, selector.relation, selector.value
        field = quotify(field.to_s)   # protects the value by quoting it if it includes a space...
        cs_criteria = ""
        case selector.selector_type
          when 'simple'
            value = value.class == String && value[0] != "(" && value[-1] != ")" ? "\"#{value}\"" : value
            cs_criteria = '%s %s %s' % [field, relation, value]
            ##  JIRA web service fails to fulfill the semantic of the request if the relationship operator is '!='.
            ##  There may be items that qualify but are not returned if the value of the field in question is null.
            ##  So, we "tune" the query condition so that qualification does happen by adding the 'OR field is null'
            ##  explicitly to the condition that we pass on in the JQL query...
            if selector.relation == '!='
              cs_criteria = "(#{cs_criteria} OR #{field} is null)"
            end
          when 'subset'
            selector.values = quotify(selector.values.dup)
            if selector.relation == 'in'
              items = selector.values.collect{|value| '%s = %s' % [field, quotify(value)]}
              #items = selector.values.collect{|value| "#{selector.field} = #{value}"}
              cs_criteria = "(#{items.join(' OR ')})"
            else # !in
              items = selector.values.collect{|value| '%s != %s' % [field, quotify(value)]}
              cs_criteria = "(#{items.join(' AND ')})"
            end
          when 'range'
            if selector.relation == 'between'
              cs_criteria = "(#{field} >= #{quotify(selector.low_value)} AND #{field} <= #{quotify(selector.high_value)})"
            else # !between
              cs_criteria = "(#{field} < #{quotify(selector.low_value)} OR #{field} > #{quotify(selector.high_value)})"
            end
        end

        return cs_criteria
      end

      def find_updates(reference_time)
        # Find artifacts that have been updated since reference_time (which is in UTC)
        #   that also have a non-null external ID field

        delta_minutes = get_relative_minutes(reference_time)

        RallyLogger.debug(self, "Looking for updates made within #{delta_minutes} minutes (UTC reference time: #{reference_time})")

        jql_minutes = "-#{delta_minutes}m"

        #query = %'type = "#{@artifact_type}" AND project = "#{@project}" AND "#{@external_id_field}" > 0 AND updated >= #{jql_minutes}'
        #us_criteria = ""

        specific_issue_type = "type=\"#{@artifact_type}\""
        project_match = "project = \"#{@project}\""
        matched_issue = "\"#{@external_id_field}\" > 0"
        updated_time  = "updated >= #{jql_minutes}"

        criteria = [specific_issue_type, project_match, matched_issue, updated_time]

        if @update_selectors && !@update_selectors.empty?
          @update_selectors.each do |us|
            us_criteria = construct_selector_syntax(us)
            criteria << us_criteria
          end
        end

        # if (@update_selectors.length > 0)
        #   @update_selectors.each do |us|
        #     field_name     = us.field
        #     selector_value = us.value
        #     # quote the field_name and/or the selector_value if it contains a space,
        #     # (assumes the field is a String field in this case)
        #     field_name     = "\"#{field_name}\""     if (field_name     =~ / /)
        #     selector_value = "\"#{selector_value}\"" if (selector_value =~ / /)
        #     us_criteria += " AND #{field_name} #{us.relation} #{selector_value}"
        #   end
        #   query += us_criteria
        # end
        complete_query = criteria.join(" AND ")

        RallyLogger.info(self, "Finding updates using query: #{complete_query}")
        begin
          issues = @jira_proxy.getIssuesWithJql(complete_query, nil, 0, MAX_NUM_RESULTS)
        rescue Exception => ex
          RallyLogger.error(self, "Trying to find_updates via query: \'#{complete_query}\' resulted in #{ex}")
          raise UnrecoverableException.copy(ex, self)
        end

        if issues.nil? or issues.empty?
          RallyLogger.info(self, "Found 0 updated issues in JIRA")
          return []
        end

        RallyLogger.info(self, "Found #{issues.length} updated issues in JIRA")
        return issues
      end

      def find(id)
        begin
          issue = @jira_proxy.getIssue(id)
        rescue => ex
          RallyLogger.error(self, "Trying to find #{@artifact_type} id: #{id} resulted in #{ex.message}")
          raise RecoverableException.copy(ex, self)
        end
        return issue
      end

      def find_by_external_id(external_id)
        query = %'type = "#{@artifact_type}" AND project = "#{@project}" AND #{@external_id_field} = #{external_id}'

        begin
          issues = @jira_proxy.getIssuesWithJql(query, nil, 0, MAX_NUM_RESULTS)
        rescue Exception => ex
          RallyLogger.error(self, "Trying to find_by_external_id via query: \'#{query}\' resulted in #{ex}")
          raise UnrecoverableException.copy(ex, self)
        end

        if issues.nil? || issues.empty?
          raise RecoverableException.new("Could not find #{@artifact_type} with CA Agile Central id: #{external_id}", self)
        end

        return issues.first
      end


      def user_fields
        ["Reporter", "Assignee"]
      end

      def user_by_username(username)
        cache_users
        @user_cache[username]
      end

      private
      def cache_users
        return if @user_cache
        user_cache = @jira_proxy.getAllUsers

        # transform to key value pair
        #   key is display name
        #   the value is JiraUser
        @user_cache = {}
        user_cache.each do |jira_user|
          # attributes listed in entities.rb for JiraRest
          # :name, :email, :active, :display_name, :info
          @user_cache[jira_user.name] = jira_user
        end
      end

    end

    JiraRestConnection = JiraConnection

  end
end

