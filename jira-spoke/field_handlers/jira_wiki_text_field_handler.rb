# Copyright 2001-2018 CA Technologies. All Rights Reserved.

require 'clothred'
#require 'redcloth'

# <JiraWikiTextFieldHandler>
#   <FieldName>reporter</FieldName>
# </JiraWikiTextFieldHandler>

module RallyEIF
  module WRK
    module FieldHandlers

      class JiraWikiTextFieldHandler < RallyEIF::WRK::FieldHandlers::OtherFieldHandler

        #TODO - What other fields could we have here?
        VALID_REFERENCES = ['Description']

        def initialize(field_name = nil)
          super(field_name)
        end

        # RedCloth - Wiki Text (Textile) to HTML
        def transform_out(artifact)
          #artifact is the Jira issue (bug)
          field_value = @connection.get_value(artifact, @field_name.to_s)
          return "" if field_value.nil? or field_value.length == 0

          # ||heading 1||heading 2||heading 3||         # Wiki Text
          # |_. Header |_. Header |_. Header |          # Textile

          # convert pass by reference to pass by value with .dup
          field_value = field_value.dup

          # Remove all extra line space and CR LF related to Wiki Text tables.  Extra linespace proven to be hazardous to outputted HTML.
          field_value.gsub!(/^(.*)$/) { |line| line.include?("|") ? line.strip : line }

          field_value.gsub!(/\|\|/, '|_.') # Wiki Text table to Textile table
          field_value.gsub!(/\|_\.\s*\r?\n/, "|\n") # Wiki Text table to Textile table
          field_value.gsub!(/\n----\r?\n/m, '<hr>') # Wiki Text horizontal line to HTML horizontal line
          field_value.gsub!(/\n\\\\\r?\n/m, '<br />') # Wiki Text line break to HTML line break

          # supports [http://www.rallydev.com] and [Rally|http://www.rallydev.com] and [mailto:support@rallydev.com]
          field_value.gsub!(/\[(.*?)\|(.*?)\]/, '<a href="\2">\1</a>') # Wiki Text Link to HTML Link
          field_value.gsub!(/\[(.*?)\]/, '<a href="\1">\1</a>') # Wiki Text Link to HTML Link

          # WikiText headers don't need a newline separating header elements, but Textile does
          field_value.gsub!(/(h[123456]\. .*\r\n)/, "\\1\r\n") # Wiki Text heading to Textile heading
          field_value.gsub!(/(h[123456]\. .*[^\r]\n)/, "\\1\n") # Wiki Text heading to Textile heading

          # Textile to HTML
          value = RedCloth.new(field_value).to_html
#          value = field_value # RedCloth deprecated in Ruby 2.0.0 Windows shared object

          value.gsub!(/{{(.*?)}}/m, '<code>\1</code>') # Wiki Text {{monospaced}} to HTML code
          value.gsub!(/\n+/m, "\n") # Substitute multiple new lines with single new line
          value.gsub!(/\t/, '') # Remove tabs

          return value
        end

        # ClothRed - HTML to Wiki Text (Textile)
        def transform_in(value)
          # if value is nil or an empty string, simply return a nil
          return nil if value.nil? || value.to_s.empty?

          # convert pass by reference to pass by value with .dup
          value = value.to_s.dup

          value.gsub!(/\n/, '') # Remove newline characters
          value.gsub!("<hr>", "\n----\n")

          field_value = ClothRed.new(value).to_textile

          # Post Textile processing (to Jira Text)
          # expected: "|| Header || Header || Header ||\n| Cell 1 | Cell 2 | Cell 3 |\n| Cell 1 | Cell 2 | Cell 3 |\n"
          # got: "|_.Header |_.Header |_.Header |\n| Cell 1 | Cell 2 | Cell 3 |\n| Cell 1 | Cell 2 | Cell 3 |\n" (using ==)
          field_value.gsub!(/\|_\.((.*?))\|$/, '||\1||') # Textile tables to Wiki Text tables
          field_value.gsub!(/\|_\./, '||') # Textile tables to Wiki Text tables
          field_value.gsub!(/<tbody>((.*?))<\/tbody>/m, '\1') # Remove tbody
          field_value.gsub!(/<\/?div>/, '') # deprecate
          field_value = field_value.split("\n").
              map { |line| line.strip }.join("\n") # Wiki Text, strip spaces at end of lines

          return field_value
        end

        def read_config(fh_info)
          super(fh_info)
          fieldname_element_check(fh_info)

          if (VALID_REFERENCES.index(@field_name) == nil)
            raise UnrecoverableException.new("Field name for JiraWikiTextFieldHandler must be from " +
                                                 "the following set #{VALID_REFERENCES}", self)
          end
        end
      end

    end
  end
end
