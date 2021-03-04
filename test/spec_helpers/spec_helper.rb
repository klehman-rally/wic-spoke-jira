# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require 'simplecov'

SimpleCov.start do
  add_filter "/spec/"
end

require 'date'
require 'time'
require 'securerandom'
require 'rallyeif-wrk'
require 'rallyeif-jira'


module YetiTestUtils
  class OutputFile
    def initialize(file_name)
      @file_name = file_name
      @marker = File.size(file_name)
    end

    public
    def readlines
      f = File.new(@file_name)
      f.seek(@marker, IO::SEEK_CUR)
      f.readlines
    end
  end

end

RSpec.configure do |r|
  r.tty   =  true
  r.color = true
end
