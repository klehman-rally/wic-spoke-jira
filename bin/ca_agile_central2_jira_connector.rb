#!/usr/bin/env ruby
# Copyright 2001-2018 CA Technologies. All Rights Reserved.
# $: << 'lib' << '.'

require 'rallyeif-wrk'
require 'rallyeif-jira'

begin
  RallyEIF::WRK::LoadCustomFieldHandlers.load

  connector_type = "JiraConnection"
  connector_runner = RallyEIF::WRK::ConnectorRunner.new(ARGV, connector_type)
  connector_runner.run()
rescue => ex
  RallyEIF::WRK::RallyLogger.exception(self, ex)
end