# Copyright 2001-2018 CA Technologies. All Rights Reserved.


# <JiraAgileSprintFieldHandler>
#   <FieldName></FieldName>
# </JiraAgileSprintFieldHandler>

module RallyEIF
  module WRK
    module FieldHandlers

      class JiraAgileSprintFieldHandler < OtherFieldHandler

        def initialize(field_name = nil)
          super(field_name)
        end

        def transform_out(artifact)
          #artifact is the Jira issue
          sprint_values = @connection.get_value(artifact, @field_name.to_s)
          return nil if sprint_values.nil? or sprint_values.empty?
          sprint_entry = sprint_values
          sprint_entry = sprint_values.first if sprint_values.class.name != 'String'

          if sprint_entry =~ /com.atlassian.greenhopper.service.sprint.Sprint.*\[name=(.*),closed=.*\]/
            sprint_name = $1
            return sprint_name
          end

          return nil
        end

        def transform_in(value)
          return {"name" => value}
        end

        def read_config(fh_element)
          super(fh_element)
          fieldname_element_check(fh_element)
        end

      end

    end
  end
end
