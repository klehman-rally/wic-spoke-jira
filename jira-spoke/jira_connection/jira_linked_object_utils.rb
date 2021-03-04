# Copyright 2001-2018 CA Technologies. All Rights Reserved.

#this module was designed to by included into Jira Connection
#  It therefore assumes the instance variables of Jira Connection
#  But this specific helper code can live here without adding more to the class

module RallyEIF
  module WRK

    class JiraConnection < RallyEIF::WRK::Connection

      def get_attachments(jira_issue)
        attachments = @jira_proxy.getIssueAttachmentsInfo(jira_issue.key)
        return attachments
      end

      def read_attachment_content(jira_issue, attachment_info)
        # we include the jira_issue as first arg, even though it is not used here as
        # the convention for the other spokes (TFS, HPALM) need to use the issue as the first arg.
        @jira_proxy.getAttachmentContent(attachment_info)
      end

      def set_attachments(issue, attachments)
        # attachments is an array of attachment_info items;
        # attachment_info should be a hash with the following keys and values:
        #   :filename  => attachment_filename
        #   :mimetype  => the content type of the attachment
        #   :base64content   => the base64 encoded content of the attachment (optional if filename exists)
        return nil if issue.nil?
        #attachment_file_names = attachments.collect {|att_info| att_info[:filename]}
        @jira_proxy.addAttachmentsToIssue(issue.key, attachments)
      end

      def get_comments(issue)
        return nil if issue.nil?

        comments = []
        jira_comments = @jira_proxy.getComments(issue.key)

        jira_comments.each do |jira_comment|
          comment_meta = {:author => jira_comment["author"]["name"],
                          :text => jira_comment["body"],
                          :time => jira_comment["created"],
                          :id => "#{issue.key}-#{jira_comment["id"]}"
          }
          comments.push(comment_meta)
        end

        comments
      end

      def add_comments(issue, new_comments)
        return nil if issue.nil?

        new_comments.each do |comment|
          attribution = "\nadded by CA Agile Central user: #{comment[:author]}"
          comment_body = comment[:text] + attribution
          @jira_proxy.addComment(issue.key, comment_body)
        end
      end


    end

  end
end
