# Copyright 2001-2018 CA Technologies. All Rights Reserved.

#
# A Jira user to email field handler specification in a config file looks like...
#
# <JiraUserToEmailFieldHandler>
#   <FieldName>reporter</FieldName>
# </JiraUserToEmailFieldHandler>
#

module RallyEIF
  module WRK
    module FieldHandlers

      JIRA_USERS_GROUP = 'jira-users'
      JIRA_OD_USERS_GROUP = 'users'

      class JiraUserToEmailFieldHandler < RallyEIF::WRK::FieldHandlers::OtherFieldHandler

        attr_reader :email_for
        attr_reader :cached_loaded

        def initialize(field_name = nil)
          super(field_name)
          @email_for = {}
          @cache_loaded = false
        end

        def load_cache()
          # cache all jira-user users so that we can get their email based on name
          # this might be a fairly large mallet to use (performance-wise)

          jira_users = @connection.jira_proxy.getAllUsers()
          jira_users.each { |u| @email_for[u.name] = u.email }

          @cache_loaded = true
        end

        def transform_out(artifact)
          # artifact is the JIRA issue (bug)
          #   JIRA  has Username, Full Name, Email
          ## for instance Username = 'demo' Full Name = 'Demo User' and Email = 'yeti@rallydev.com'
          # Given the artifact, use the @field_name attribute find the value of the JIRA Username
          # and lookup and return the corresponding email address in our @email_for cache
          # then return the email address associated with that username
          #

          # The unfortunate aspect here is the loading of our cache with JIRA name to email
          # addresses is better placed in the initialize method, but alas at that point
          # (and even in read_config) our instance's connection attribute is still nil as
          # the connection has not yet been # established.  So, we have to put the code here
          # to determine whether we need to load the email_for cache.
          #
          load_cache if !@cache_loaded

          jira_user = @connection.get_value(artifact, @field_name.to_s)

          email_addr = @email_for[jira_user]
          return email_addr
        end

        def transform_in(value)
          #
          # Given Rally username value (usually an email address, eg., somebody@somewhere.com
          # return the key in @email_for corresponding the the value
          #
          load_cache if !@cache_loaded

          hit = @email_for.keys.select { |name| @email_for[name].downcase == value.downcase }
          return hit.first if not hit.nil? and hit.length != 0
          return nil
        end

        def read_config(fh_info)
          super(fh_info)
          fieldname_element_check(fh_info)
        end

      end

    end
  end
end
