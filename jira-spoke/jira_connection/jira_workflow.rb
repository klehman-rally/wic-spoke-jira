# Copyright 2001-2018 CA Technologies. All Rights Reserved.

module RallyEIF
  module WRK

    module JiraWorkflow

      class JiraFieldProxy
        attr_reader :name, :value

        def initialize(name, value)
          @name = name
          @value = value
        end
      end

      def execute_actions(jira_issue, actions, int_work_item)
        RallyEIF::WRK::RallyLogger.debug(self, "execute_actions: #{actions.inspect}")
        updated_issue = nil
        actions.each do |action|
##
#     puts "execute_actions, action: #{action}"
##
          action_params = []
          if not action['Field'].nil?
            action['Field'].each_with_index do |field, index|
              #if valid_field_for_action?(jira_issue, action['ID'], action['Field'][index])
              if valid_field_for_action?(jira_issue, action['Name'], action['Field'][index])
                field_value = hash_value_for(int_work_item, field)
                action_params << JiraFieldProxy.new(field, field_value) if !field_value.nil?
              else
                field, name = action['Field'], action['Name']
                problem = "#{field} field is not available for action #{name} for issue #{jira_issue.key}"
                raise RallyEIF::WRK::RecoverableException.new(problem, self)
              end
            end
          end
##
#    puts "  ... calling progress_workflow(issue.key=#{jira_issue.key}, action_id=#{action['ID']}, action_name=#{action['Name']}, action_params=#{action_params})"
##
          updated_issue = progress_workflow(jira_issue, action['Name'], action_params)
        end

        return updated_issue
      end

      def progress_workflow(issue, action_name, action_params)
        aps = action_params.collect { |p| "#{p.name} #{p.value}" } if not action_params.nil?
        pending_activity = "Progressing workflow for #{issue.key} with status |#{issue.Status}| " +
            "via #{action_name} with params: #{aps.join(', ')}"
        RallyEIF::WRK::RallyLogger.debug(self, pending_activity)

        available_actions = @jira_proxy.getTransitions(issue.key)
        action = available_actions.find { |action, info| action == action_name }
        if action.nil?
          RallyEIF::WRK::RallyLogger.warning(self, "Couldn't update JIRA status using action #{action_name} for issue #{issue.key}")
          begin
            actions = available_actions.keys.collect { |a| "#{a["end_state_name"]} (id=#{a["action_id"]}) " }
            RallyEIF::WRK::RallyLogger.warning(self, "Allowable actions are: #{actions}")
          rescue => ex
            RallyEIF::WRK::RallyLogger.error(self, "Unable to obtain allowable actions from: #{available_actions.inspect}")
          end
          raise RallyEIF::WRK::RecoverableException.new("#{action_name} action not allowed in this transition", self)
        end

        resolution = nil
        resolution = action_params.first.value if !action_params.empty? && action_params.first.name == 'resolution'
        begin
          updated_issue = @jira_proxy.transitionIssueState(issue.key, action_name, resolution)
        rescue StandardError => ex
          RallyEIF::WRK::RallyLogger.error(self, "Unable to transition issue state: #{ex.message}")
          raise RallyEIF::WRK::UnrecoverableException.copy(ex, self)
        end

        return updated_issue

      end

      def validate_action_name(available_actions, id, name)
        if available_actions.nil?
          msg = "in validate_action_name, available_actions is nil, this is unexpected"
          raise RallyEIF::WRK::UnrecoverableException.new(msg, self)
        end
        #action = available_actions["transitions"].find { |a| a["id"] == id }
        action = available_actions.find { |action, info| name == info['end_state_name'] }
        if !action.nil? && action["name"] != name
          msg = "In workflow definition, there is an <Action> definition with id #{id} and name #{name}, "
          msg << "but the name from JIRA for action id #{id} is #{action["end_state_name"]}"
          msg << " -Check for trailing whitespace."
          raise RallyEIF::WRK::UnrecoverableException.new(msg, self)
        end
      end

      def valid_field_for_action?(issue, action_name, field_name)
        fields = @jira_proxy.getFieldsForAction(issue.key, action_name)
        result = fields.find { |f| f[0] == field_name or f[1] == field_name }
        return !result.nil?
      end

#  def valid_field_for_action?(issue, action_id, field_name)
#    fields = @jira_proxy.getFieldsForAction(issue.key, action_id)
#    result = fields.find { |f| f[0] == field_name or f[1] == field_name}
#    return !result.nil?
#  end

#case-insensitive hash lookup
      def hash_value_for(hash, desired_key)
        hash.keys.each do |key|
          return hash[key] if key.to_s.downcase == desired_key.downcase
        end
        return nil
      end


    end

  end
end
