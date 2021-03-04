# Copyright 2001-2018 CA Technologies. All Rights Reserved.

# <JiraNewlineFieldHandler>
#   <FieldName>reporter</FieldName>
# </JiraNewlineFieldHandler>

module RallyEIF
  module WRK
    module FieldHandlers

      class JiraNewlineFieldHandler < RallyEIF::WRK::FieldHandlers::OtherFieldHandler

        #TODO - What other fields could we have here?
        VALID_REFERENCES = ['Description']

        def initialize(field_name = nil)
          super(field_name)
        end

        def transform_out(artifact)
          #artifact is the Jira issue (bug)
          value = @connection.get_value(artifact, @field_name.to_s)
          if !value.nil?
            value.gsub(/\n/, '<br />')
          else
            value
          end
        end

        def transform_in(value)
          if !value.nil?
            value.gsub(/<br \/>/i, "\n").gsub(/<br>/i, "\n") if !value.nil?
          else
            value
          end
        end

        def read_config(fh_info)
          super(fh_info)
          fieldname_element_check(fh_info)

          if (VALID_REFERENCES.index(@field_name) == nil)
            raise UnrecoverableException.new("Field name for JiraNewlineFieldHandler must be from " +
                                                 "the following set #{VALID_REFERENCES}", self)
          end
        end
      end

    end
  end
end
