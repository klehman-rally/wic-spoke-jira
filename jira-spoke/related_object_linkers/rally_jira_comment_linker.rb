# Copyright 2001-2018 CA Technologies. All Rights Reserved.

#require 'yeti/related_object_linkers/related_object_linker'
#require 'yeti/utils/rally_logger'
#require 'yeti/utils/xml_utils'
#require 'sanitize'


# <RallyJiraCommentLinker>
# </RallyJiraCommentLinker>

module RallyEIF
  module WRK
    module RelatedObjectLinkers

      class RallyJiraCommentLinker < RallyEIF::WRK::RelatedObjectLinkers::RelatedObjectLinker

        RJCONNECTOR_COMMENT_START = "RallyJiraConnector at: "

        #RJCONNECTOR_COMMENT_END  = " <br> "  # this was in effect until 2014-04-09
        #RJCONNECTOR_COMMENT_END  = " <br /> " # the new syntax effective 2014-04-10
        RJCONNECTOR_COMMENT_END  = "(\n| <br \/> | <br> )" # new way (eff 2014-12-xx) is to use just a "\n" char
                                                           # but we have to accommodate prior syntax
        RALLY_USER_IDENT = "added by CA Agile Central user: "
        NORM_TIME = "%Y-%m-%dT%H:%M:%S"

        def read_config(config_xml)
          super(config_xml)
          @direction = "both" if @direction.nil?
        end

        def link_related_objects_in_rally(rally_item, jira_issue, operation, last_run=nil)
          return nil if ((@direction.downcase != "to_rally") && (@direction.downcase != "both"))
          jira_comments  = @other_connection.get_comments(jira_issue)
          rally_comments = @rally_connection.get_comments(rally_item)

          comments_to_go = []
          jira_comments.each do |jira_comment|
            next if artifact_has_comment?(rally_comments, jira_comment)
            RallyLogger.debug(self, "Adding comment: #{jira_comment[:text]} to CA Agile Central for #{rally_item.FormattedID}")
            comments_to_go << build_comment_text_rally(jira_comment)
          end
          return if comments_to_go.length == 0
          @rally_connection.add_comments(rally_item, comments_to_go)
        end

        def link_related_objects_in_other(rally_item, jira_issue, operation, last_run=nil)
          return nil if (@direction.downcase != "to_other") && (@direction != "both")
          jira_comments  = @other_connection.get_comments(jira_issue)
          rally_comments = @rally_connection.get_comments(rally_item)

          comments_to_go = []
          rally_comments.each do |convo_post|
            next if artifact_has_comment?(jira_comments, convo_post)
            RallyLogger.debug(self, "Copying comment: #{convo_post[:text]} from CA Agile Central #{rally_item.FormattedID}")
            comments_to_go << build_comment_text_jira(convo_post)
          end
          return if comments_to_go.length == 0
          @other_connection.add_comments(jira_issue, comments_to_go)
        end

        #comments_list comes from a connection that has implemented get_comments  - it is an array of comment_info
        #comment_info should be a hash with the following info:
        #  comment_info[:text]    = text of comment
        #  comment_info[:author]  = comment author in the system
        #  comment_info[:time]    = original time of comment
        #  comment_info[:id]      = identifier for the comment provided by the originating system
        def artifact_has_comment?(comments_list, candidate_comment)

          src = normalize_connector_comment(candidate_comment)
          src_defootered = src[:text].gsub(/addedbyRallyuser:.*$/, '')
##
##puts "=" * 60
##puts "src comment"
##puts "    :time |#{src[:time]}|"
##puts "    :text |#{src[:text]}|"
##puts "      defootered |#{src_defootered}|"
##puts ""
##$stdout.flush()
##
          comments_list.each do |list_comment_info|
            tgt = normalize_connector_comment(list_comment_info)
##
##puts "tgt comment"
##puts "    :time |#{tgt[:time]}|"
##puts "    :text |#{tgt[:text]}|"
##puts "-" * 60
##puts ""
##$stdout.flush()
##
            if (tgt[:text] == src[:text]) && (tgt[:time].to_s == src[:time].to_s)
##
##        puts "src and tgt comment item matches EXACTLY!"
##        $stdout.flush()
##
              return true
            end
            if src[:time].to_s == tgt[:time].to_s
              tgt_defootered = tgt[:text].gsub(/addedbyRallyuser:.*$/, '')
##
##         puts "  tgt defootered |#{tgt_defootered}|"
##
              if src_defootered == tgt_defootered
##
##           puts "src and tgt comment item match after truncating 'addedbyRallyuser:.*' footer text"
##           $stdout.flush()
##
                return true
              end
            end
          end
##
##puts "NO match for src comment compared with any tgt comment"
##$stdout.flush()
##
          false
        end

        def build_connector_comment_preamble(comment_info)
          comment_time = comment_info[:time]
          comment_time = DateTime.parse(comment_info[:time]) if comment_time.class == String
          comment_time = comment_time.strftime(NORM_TIME)

          comment_text = "#{RJCONNECTOR_COMMENT_START}#{comment_time}, "
          comment_text << "by: #{comment_info[:author]}\n"
        end

        def build_comment_text_jira(comment_info)
          base_text = build_connector_comment_preamble(comment_info)
          orig_text = comment_info[:text]
          #new_text = orig_text.gsub(RALLY_LINE_BREAK,"\n")

          #lamda stuff credit: https://gist.github.com/1831658
          #  https://github.com/rgrove/sanitize - using transformers
          div_to_nl = lambda do |env|
            node = env[:node]
            node_name = env[:node_name]
            return if env[:is_whitelisted] || !node.element?
            return unless node_name == 'div'
            node.add_next_sibling "\n"
          end

          # new_text = Sanitize.clean(orig_text,
          #                           :transformers => [div_to_nl],
          #                           :remove_contents => ['style'],
          #                           :whitespace_elements => []
          #                          )

          new_text = Xanitize.clean(orig_text)

          base_text << new_text
          return {:text => base_text, :author => comment_info[:author]}
        end

        def build_comment_text_rally(comment_info)
          base_text = build_connector_comment_preamble(comment_info)
          orig_text = comment_info[:text]
          split_text = orig_text.split("\n")
          new_text = split_text.collect { |line| "<div>#{line}</div>" }
          base_text << new_text.join
          return {:text => base_text}
        end

        def normalize_connector_comment(orig_comment_info)
          comment_text = orig_comment_info[:text]
          #comment already done by the connector
          if comment_text.start_with?(RJCONNECTOR_COMMENT_START)
            comment_text.gsub!(/\r\n/, "\n")

            # was this a comment added by the connector in Rally?
            if comment_text =~ /^(#{RJCONNECTOR_COMMENT_START})([0-9:T-]+), by: ([^\s]+)\s+(<div>.*)$/
              rjconn_text = $1
              orig_time   = $2
              conn_poster = $3
              orig_text   = $4
            else  # this was a comment added by the Connector to JIRA
              # strip off any RallyJiraConnector prefix
              nuggets  = comment_text.scan(/^#{RJCONNECTOR_COMMENT_START}([0-9T:-]+), by: ([^\n]+)#{RJCONNECTOR_COMMENT_END}(.*)\n#{RALLY_USER_IDENT}(.*)$/m).first
              orig_time, conn_poster, rjconn_comment_end, orig_text, rally_poster = nuggets
            end

            cleaned_text = clean_text(orig_text)
            return {:time => orig_time, :text => cleaned_text}
          end

          #probably a new comment
          norm_time = orig_comment_info[:time]
          norm_text = clean_text(orig_comment_info[:text])
          norm_time = DateTime.parse(norm_time) if norm_time.is_a?(String)
          norm_time = norm_time.strftime(NORM_TIME)
          return {:time => norm_time, :text => norm_text}
        end

        def clean_text(original_text)
          # squish any newlines or space chars
          squished = original_text.gsub(/\n/, "").gsub(" ", "")
          # then use our poor man's sanitize to remove markup
          washed = Xanitize.clean(squished)
          washed.gsub!("\n", '') # for string comparison only, we strip out the newlines from the original_text
          return washed
        end

        def validate()
          true
        end

      end
    end
  end
end
