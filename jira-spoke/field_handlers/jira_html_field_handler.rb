# Copyright 2001-2018 CA Technologies. All Rights Reserved.

# <JiraHTMLFieldHandler>
#   <FieldName>reporter</FieldName>
# </JiraHTMLFieldHandler>

module RallyEIF
  module WRK
    module FieldHandlers

      class JiraHTMLFieldHandler < RallyEIF::WRK::FieldHandlers::OtherFieldHandler

        #TODO - What other fields could we have here?
        VALID_REFERENCES = ['Description']

        def initialize(field_name = nil)
          super(field_name)
        end

        def transform_out(artifact)
          #artifact is the Jira issue (bug)
          prefix = '{html}'
          suffix = '{html}'
          field_value = @connection.get_value(artifact, @field_name.to_s)
          return "" if field_value.nil? or field_value.length == 0
          value = field_value.strip()
          if value =~ /^#{prefix}(.*)#{suffix}$/ # value wrapped in prefix and suffix?
            return "#{$1}"
          else
            return value
          end
        end

        def transform_in(value)
          #if value is an empty string, simply return value
          #if the value is already wrapped with the prefix and suffix, pass it back unchanged
          #otherwise, wrap the value in the prefix and suffix
          value = value.to_s
          return value if value.length == 0
          prefix = '{html}'
          suffix = '{html}'
          if value =~ /^#{prefix}(.*)#{suffix}$/
            return value
          else
            return "#{prefix}#{value}#{suffix}"
          end
        end

        def read_config(fh_element)
          super(fh_element)
          fieldname_element_check(fh_element)

          if (VALID_REFERENCES.index(@field_name) == nil)
            raise UnrecoverableException.new("Field name for JiraHTMLFieldHandler must be from " +
                                                 "the following set #{VALID_REFERENCES}", self)
          end
        end
      end

    end
  end
end
