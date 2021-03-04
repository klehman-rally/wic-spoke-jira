# Copyright 2001-2018 CA Technologies. All Rights Reserved.

require 'xmlsimple'

module RallyEIF
  module WRK
    module Utils

      class JiraWorkflowReader

        def self.read_workflow_file(filename)
          #RallyLogger.info(JiraWorkflowReader, "#{filename}")
          RallyEIF::WRK::RallyLogger.info(JiraWorkflowReader, "#{File.basename(filename)}")
          begin
            workflow = XmlSimple.xml_in(filename,
                                        {'KeyAttr' => {'Step' => 'JiraStatusName', 'Transition' => 'JiraStatusName'}})
            return workflow

          rescue REXML::ParseException => ex
            error_msg = "Invalid workflow file (#{filename}) - #{ex.continued_exception}"
            raise RallyEIF::WRK::UnrecoverableException.new(error_msg, self)

          rescue Exception => ex
            raise RallyEIF::WRK::UnrecoverableException.copy(ex, self)
          end
        end

      end

    end
  end
end
