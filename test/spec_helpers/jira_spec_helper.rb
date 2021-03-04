# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require_relative 'spec_helper'
require_relative "#{File.dirname(__FILE__)}/../../lib/rallyeif/jira/jira_connection/jira_connection"

include RallyEIF::WRK
include YetiTestUtils
Konfabulator = RallyEIF::WRK::Konfabulator

module JiraSpecHelper

  YETI_PASSWORD = "Vistabahn"

  JIRA_SERVER = ENV['JIRA_SERVER'] || 'http://10.23.22.11:8080'   # int-hobart on GCP saas-rally-dev project with Jira 7.8
  RALLY_STATE_SUBMITTED  = 'Submitted'
  RALLY_STATE_OPEN       = 'Open'
  RALLY_STATE_REOPENED   = 'Reopened'
  RALLY_STATE_FIXED      = 'Fixed'
  RALLY_STATE_CLOSED     = 'Closed'

  JIRA_STATUS_OPEN       = 'Open'
  JIRA_STATUS_INPROGRESS = 'In Progress'
  JIRA_STATUS_REOPENED   = 'Reopened'
  JIRA_STATUS_RESOLVED   = 'Resolved'
  JIRA_STATUS_CLOSED     = 'Closed'
  JIRA_STATUS_INTEST     = 'In Test'

  # JIRA 7 Simplified workflow status values...
  JIRA_STATUS_TODO       = 'To Do'
  #JIRA_STATUS_INPROGRESS = 'In Progress'   # already defined above
  JIRA_STATUS_INREVIEW   = 'In Review'
  JIRA_STATUS_DONE       = 'Done'

  JIRA7_PRIORITY_MAPPING = "\
                <FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally> <Other>Highest</Other></Field>
                    <Field><Rally>High Attention</Rally>      <Other>High</Other></Field>
                    <Field><Rally>Normal</Rally>              <Other>Medium</Other></Field>
                    <Field><Rally>Low</Rally>                 <Other>Low</Other></Field>
                    <Field><Rally>Trivial</Rally>             <Other>Lowest</Other></Field>
                    <Field><Rally>None</Rally>                <Other>Medium</Other></Field>
                </Mappings>
  "
  JIRA7_STATUS_MAPPING = "\
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally> <Other>To Do</Other></Field>
                    <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                    <Field><Rally>Fixed</Rally>     <Other>In Review</Other></Field>
                    <Field><Rally>Closed</Rally>    <Other>Done</Other></Field>
                </Mappings>
  "
  JIRA_STATUS_ISOLATED   = 'IsolatedTransition'


  AC_ACCESS = "<Url>rally1.rallydev.com</Url>
        <WorkspaceName>JIRA 7 Testing</WorkspaceName>
        <Projects>
            <Project>Sample Project</Project>
        </Projects>
        <User>yeti@rallydev.com</User>
        <Password>#{YETI_PASSWORD}</Password>
"

  JIRA_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <CopySelectors>
          <CopySelector>Status != Done</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != High</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/simplified_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Priority</Rally>    <Other>Priority</Other></Field>
            <Field><Rally>State</Rally>       <Other>Status</Other></Field>
            <Field><Rally>Severity</Rally>    <Other>Severity</Other></Field>
            <Field><Rally>Resolution</Rally>  <Other>Resolution</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherEnumFieldHandler>
                #{JIRA7_PRIORITY_MAPPING}
                <!--FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally> <Other>Blocker</Other></Field>
                    <Field><Rally>High Attention</Rally>      <Other>Critical</Other></Field>
                    <Field><Rally>Normal</Rally>              <Other>Major</Other></Field>
                    <Field><Rally>Low</Rally>                 <Other>Minor</Other></Field>
                    <Field><Rally>Trivial</Rally>             <Other>Trivial</Other></Field>
                </Mappings-->
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Resolution</FieldName>
                <Mappings>
                    <Field><Rally>Fixed</Rally>            <Other>Fixed</Other></Field>
                    <Field><Rally>Won't Fix</Rally>        <Other>Won't Fix</Other></Field>
                    <Field><Rally>Duplicate</Rally>        <Other>Duplicate</Other></Field>
                    <Field><Rally>Incomplete</Rally>       <Other>Incomplete</Other></Field>
                    <Field><Rally>Cannot Reproduce</Rally> <Other>Cannot Reproduce</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                #{JIRA7_STATUS_MAPPING}
                <!--FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally> <Other>Open</Other></Field>
                    <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                    <Field><Rally>Reopened</Rally>  <Other>Reopened</Other></Field>
                    <Field><Rally>Fixed</Rally>     <Other>Resolved</Other></Field>
                    <Field><Rally>Closed</Rally>    <Other>Closed</Other></Field>
                </Mappings-->
            </OtherEnumFieldHandler>

            <!--  enable this for experimentation...
            <JiraHTMLFieldHandler>
               <Field>Description</Field>
            </JiraHTMLFieldHandler>
            -->

            <OtherEnumFieldHandler>
                <FieldName>Severity</FieldName>
                <Mappings>
                    <Field><Rally>Crash/Data Loss</Rally> <Other>Crash/Data Loss</Other></Field>
                    <Field><Rally>Major Problem</Rally>   <Other>Major Problem</Other></Field>
                    <Field><Rally>Minor Problem</Rally>   <Other>Minor Problem</Other></Field>
                    <Field><Rally>Cosmetic</Rally>        <Other>Cosmetic</Other></Field>
                    <Field><Rally>None</Rally>            <Other>Cosmetic</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Assignee</FieldName>
                 <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
           </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Reporter</FieldName>
                <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_CONFIG_FILE_WITH_PROXY = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <!--Url>https://alligator-tiers.atlassian.net</Url-->
        <Url>http://hobart.f4tech.com:8080</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ProxyURL>http://supp-proxy-01.f4tech.com:3128</ProxyURL>
        <ProxyUser>connector</ProxyUser>
        <ProxyPassword>rallydev</ProxyPassword>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>JEST</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Priority</Rally>    <Other>Priority</Other></Field>
            <Field><Rally>State</Rally>       <Other>Status</Other></Field>
            <Field><Rally>Severity</Rally>    <Other>Severity</Other></Field>
            <Field><Rally>Resolution</Rally>  <Other>Resolution</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally> <Other>Blocker</Other></Field>
                    <Field><Rally>High Attention</Rally>      <Other>Critical</Other></Field>
                    <Field><Rally>Normal</Rally>              <Other>Major</Other></Field>
                    <Field><Rally>Low</Rally>                 <Other>Minor</Other></Field>
                    <Field><Rally>Trivial</Rally>             <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Resolution</FieldName>
                <Mappings>
                    <Field><Rally>Fixed</Rally>            <Other>Fixed</Other></Field>
                    <Field><Rally>Won't Fix</Rally>        <Other>Won't Fix</Other></Field>
                    <Field><Rally>Duplicate</Rally>        <Other>Duplicate</Other></Field>
                    <Field><Rally>Incomplete</Rally>       <Other>Incomplete</Other></Field>
                    <Field><Rally>Cannot Reproduce</Rally> <Other>Cannot Reproduce</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally> <Other>Open</Other></Field>
                    <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                    <Field><Rally>Reopened</Rally>  <Other>Reopened</Other></Field>
                    <Field><Rally>Fixed</Rally>     <Other>Resolved</Other></Field>
                    <Field><Rally>Closed</Rally>    <Other>Closed</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <!--  enable this for experimentation...
            <JiraHTMLFieldHandler>
               <Field>Description</Field>
            </JiraHTMLFieldHandler>
            -->

            <OtherEnumFieldHandler>
                <FieldName>Severity</FieldName>
                <Mappings>
                    <Field><Rally>Crash/Data Loss</Rally> <Other>Critical</Other></Field>
                    <Field><Rally>5-Urgent High</Rally>   <Other>Severe</Other></Field>
                    <Field><Rally>Major Problem</Rally>   <Other>Major</Other></Field>
                    <Field><Rally>Minor Problem</Rally>   <Other>Minor</Other></Field>
                    <Field><Rally>Cosmetic</Rally>        <Other>Cosmetic</Other></Field>
                    <Field><Rally>None</Rally>            <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_CONFIG_FILE_RESOLVE_EDIT = "
<config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <ArtifactType>bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TSTRT</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Priority</Rally>    <Other>Priority</Other></Field>
            <Field><Rally>State</Rally>       <Other>Status</Other></Field>
            <Field><Rally>Severity</Rally>    <Other>Severity</Other></Field>
            <Field><Rally>Resolution</Rally>  <Other>Resolution</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally> <Other>Blocker</Other></Field>
                    <Field><Rally>High Attention</Rally>      <Other>Critical</Other></Field>
                    <Field><Rally>Normal</Rally>              <Other>Major</Other></Field>
                    <Field><Rally>Low</Rally>                 <Other>Minor</Other></Field>
                    <Field><Rally>Trivial</Rally>             <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Resolution</FieldName>
                <Mappings>
                    <Field><Rally>Fixed</Rally>            <Other>Fixed</Other></Field>
                    <Field><Rally>Won't Fix</Rally>        <Other>Won't Fix</Other></Field>
                    <Field><Rally>Duplicate</Rally>        <Other>Duplicate</Other></Field>
                    <Field><Rally>Incomplete</Rally>       <Other>Incomplete</Other></Field>
                    <Field><Rally>Cannot Reproduce</Rally> <Other>Cannot Reproduce</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally> <Other>Open</Other></Field>
                    <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                    <Field><Rally>Reopened</Rally>  <Other>Reopened</Other></Field>
                    <Field><Rally>Fixed</Rally>     <Other>Resolved</Other></Field>
                    <Field><Rally>Closed</Rally>    <Other>Closed</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <!--  enable this for experimentation...
            <JiraHTMLFieldHandler>
               <Field>Description</Field>
            </JiraHTMLFieldHandler>
            -->

            <OtherEnumFieldHandler>
                <FieldName>Severity</FieldName>
                <Mappings>
                    <Field><Rally>Crash/Data Loss</Rally> <Other>Critical</Other></Field>
                    <Field><Rally>5-Urgent High</Rally>   <Other>Severe</Other></Field>
                    <Field><Rally>Major Problem</Rally>   <Other>Major</Other></Field>
                    <Field><Rally>Minor Problem</Rally>   <Other>Minor</Other></Field>
                    <Field><Rally>Cosmetic</Rally>        <Other>Cosmetic</Other></Field>
                    <Field><Rally>None</Rally>            <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</config>"

  JIRA_NON_BUG_CONFIG_FILE = "
  <Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>HierarchicalRequirement</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <!--CopySelector>ScheduleState = Open</CopySelector-->
           <CopySelector>ScheduleState = Defined</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <ArtifactType>New Feature</ArtifactType>
        <Project>NFI</Project>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <WorkflowFile>configs/jira_issue_workflow.xml</WorkflowFile>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>            <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally>     <Other>Description</Other></Field>
            <Field><Rally>ScheduleState</Rally>   <Other>Status</Other></Field>
            <Field><Rally>Owner</Rally>           <Other>Reporter</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherEnumFieldHandler>
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Defined</Rally>      <Other>Open</Other></Field>
                    <Field><Rally>In-Progress</Rally>  <Other>In Progress</Other></Field>
                    <Field><Rally>Completed</Rally>    <Other>Resolved</Other></Field>
                    <Field><Rally>Reopened</Rally>     <Other>Reopened</Other></Field>
                    <Field><Rally>Accepted</Rally>     <Other>Closed</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <Services>COPY_JIRA_TO_RALLY, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>
"

  JIRA_CUSTOM_WORKFLOW_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <!--
          <CopySelectors>
            <CopySelector>State = Open</CopySelector>
          </CopySelectors>
        -->
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>CWF</Project>
        <WorkflowFile>configs/jira_custom_workflow.xml</WorkflowFile>
       <!--
          <CopySelectors>
            <CopySelector>Priority != 3</CopySelector>
          </CopySelectors>
       -->
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally><Other>Summary</Other></Field>
            <Field><Rally>Description</Rally><Other>Description</Other></Field>
            <Field><Rally>Priority</Rally><Other>Priority</Other></Field>
            <Field><Rally>State</Rally><Other>Status</Other></Field>
            <Field><Rally>Resolution</Rally><Other>Resolution</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherEnumFieldHandler>
                <FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally><Other>Blocker</Other></Field>
                    <Field><Rally>High Attention</Rally><Other>Critical</Other></Field>
                    <Field><Rally>Normal</Rally><Other>Major</Other></Field>
                    <Field><Rally>Low</Rally><Other>Minor</Other></Field>
                    <Field><Rally>Trivial</Rally><Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
            <OtherEnumFieldHandler>
                <FieldName>Resolution</FieldName>
                <Mappings>
                    <Field><Rally>Code Change</Rally><Other>Fixed</Other></Field>
                    <Field><Rally>Software Limitation</Rally><Other>Won't Fix</Other></Field>
                    <Field><Rally>Duplicate</Rally><Other>Duplicate</Other></Field>
                    <Field><Rally>Need More Information</Rally><Other>Incomplete</Other></Field>
                    <Field><Rally>Not a Defect</Rally><Other>Cannot Reproduce</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
            <OtherEnumFieldHandler>
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally><Other>Open</Other></Field>
                    <Field><Rally>Open</Rally><Other>In Progress</Other></Field>
                    <Field><Rally>Reopened</Rally><Other>Reopened</Other></Field>
                    <Field><Rally>Fixed</Rally><Other>Resolved</Other></Field>
                    <Field><Rally>Closed</Rally><Other>Closed</Other></Field>
                    <Field><Rally>TestInProgress</Rally><Other>In Testing</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"


  JIRA_ATTACHMENT_CONFIG_FILE = "
  <Config>
      <RallyConnection>
          #{AC_ACCESS}
          <ArtifactType>Defect</ArtifactType>
          <ExternalIDField>JiraKey</ExternalIDField>
          <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
          <CopySelectors>
             <CopySelector>State = Open</CopySelector>
          </CopySelectors>
      </RallyConnection>
      <JiraConnection>
          <Url>#{JIRA_SERVER}</Url>
          <User>devuser</User>
          <Password>jiradev</Password>
          <ArtifactType>Bug</ArtifactType>
          <ExternalIDField>RallyID</ExternalIDField>
          <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
          <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
          <Project>RW</Project>
          <CopySelectors>
            <CopySelector>Status != Closed</CopySelector>
          </CopySelectors>
          <UpdateSelectors>
            <UpdateSelector>Priority != Highest</UpdateSelector>
          </UpdateSelectors>
          <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
          <FinalStatus>Closed</FinalStatus>
      </JiraConnection>
      <Connector>
          <FieldMapping>
              <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
              <Field><Rally>Description</Rally> <Other>Description</Other></Field>
              <Field><Rally>Priority</Rally>    <Other>Priority</Other></Field>
              <Field><Rally>State</Rally>       <Other>Status</Other></Field>
              <Field><Rally>Severity</Rally>    <Other>Severity</Other></Field>
              <Field><Rally>Resolution</Rally>  <Other>Resolution</Other></Field>
              <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
              <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
          </FieldMapping>
          <OtherFieldHandlers>

              <OtherUserFieldHandler>
                  <FieldName>Assignee</FieldName>
                  <Domain>rallydev.com</Domain>
              </OtherUserFieldHandler>

              <OtherUserFieldHandler>
                  <FieldName>Reporter</FieldName>
                  <Domain>rallydev.com</Domain>
              </OtherUserFieldHandler>

              <OtherEnumFieldHandler>
                  <FieldName>Priority</FieldName>
                  <Mappings>
                      <Field><Rally>Resolve Immediately</Rally> <Other>Highest</Other></Field>
                      <Field><Rally>High Attention</Rally>      <Other>High</Other></Field>
                      <Field><Rally>Normal</Rally>              <Other>Medium</Other></Field>
                      <Field><Rally>Low</Rally>                 <Other>Low</Other></Field>
                      <Field><Rally>Trivial</Rally>             <Other>Lowest</Other></Field>
                  </Mappings>
              </OtherEnumFieldHandler>

              <OtherEnumFieldHandler>
                  <FieldName>Resolution</FieldName>
                  <Mappings>
                      <Field><Rally>Fixed</Rally>            <Other>Fixed</Other></Field>
                      <Field><Rally>Won't Fix</Rally>        <Other>Won't Fix</Other></Field>
                      <Field><Rally>Duplicate</Rally>        <Other>Duplicate</Other></Field>
                      <Field><Rally>Incomplete</Rally>       <Other>Incomplete</Other></Field>
                      <Field><Rally>Cannot Reproduce</Rally> <Other>Cannot Reproduce</Other></Field>
                  </Mappings>
              </OtherEnumFieldHandler>

              <OtherEnumFieldHandler>
                  <FieldName>Status</FieldName>
                  <Mappings>
                      <Field><Rally>Submitted</Rally> <Other>Open</Other></Field>
                      <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                      <Field><Rally>Reopened</Rally>  <Other>Reopened</Other></Field>
                      <Field><Rally>Fixed</Rally>     <Other>Resolved</Other></Field>
                      <Field><Rally>Closed</Rally>    <Other>Closed</Other></Field>
                  </Mappings>
              </OtherEnumFieldHandler>

              <!--  enable this for experimentation...
              <JiraHTMLFieldHandler>
                 <Field>Description</Field>
              </JiraHTMLFieldHandler>
              -->

              <OtherEnumFieldHandler>
                  <FieldName>Severity</FieldName>
  <!-- enabled for JIRA 4.2 testing -->
                  <Mappings>
                      <Field><Rally>Crash/Data Loss</Rally> <Other>Critical</Other></Field>
                      <Field><Rally>5-Urgent High</Rally>   <Other>Severe</Other></Field>
                      <Field><Rally>Major Problem</Rally>   <Other>Major</Other></Field>
                      <Field><Rally>Minor Problem</Rally>   <Other>Minor</Other></Field>
                      <Field><Rally>Cosmetic</Rally>        <Other>Cosmetic</Other></Field>
                      <Field><Rally>None</Rally>            <Other>Cosmetic</Other></Field>
                  </Mappings>
              </OtherEnumFieldHandler>
                                   <!--
              <OtherUserFieldHandler>
                  <FieldName>Assignee</FieldName>
                  <Domain>rallydev.com</Domain>
              </OtherUserFieldHandler>

              <OtherUserFieldHandler>
                  <FieldName>Reporter</FieldName>
                  <Domain>rallydev.com</Domain>
              </OtherUserFieldHandler> -->

            <OtherEnumFieldHandler>
                <FieldName>Assignee</FieldName>
                 <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Reporter</FieldName>
                 <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
          </OtherFieldHandlers>

        <RelatedObjectLinkers>
          <RallyAttachmentLinker />
          <RallyJiraCommentLinker />
        </RelatedObjectLinkers>

      </Connector>
      <ConnectorRunner>
          <Preview>false</Preview>
          <LogLevel>Warning</LogLevel>
          <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
      </ConnectorRunner>
  </Config>"

  JIRA_TARGET_RELEASE_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Assignee</FieldName>
                 <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
           </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Reporter</FieldName>
                <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>yeti</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_RESO_TEST_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TSTRT</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Priority</Rally>    <Other>Priority</Other></Field>
            <Field><Rally>State</Rally>       <Other>Status</Other></Field>
            <Field><Rally>Severity</Rally>    <Other>Severity</Other></Field>
            <Field><Rally>Resolution</Rally>  <Other>Resolution</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Priority</FieldName>
                <Mappings>
                    <Field><Rally>Resolve Immediately</Rally> <Other>Blocker</Other></Field>
                    <Field><Rally>High Attention</Rally>      <Other>Critical</Other></Field>
                    <Field><Rally>Normal</Rally>              <Other>Major</Other></Field>
                    <Field><Rally>Low</Rally>                 <Other>Minor</Other></Field>
                    <Field><Rally>Trivial</Rally>             <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Resolution</FieldName>
                <Mappings>
                    <Field><Rally>Fixed</Rally>            <Other>Fixed</Other></Field>
                    <Field><Rally>Won't Fix</Rally>        <Other>Won't Fix</Other></Field>
                    <Field><Rally>Duplicate</Rally>        <Other>Duplicate</Other></Field>
                    <Field><Rally>Incomplete</Rally>       <Other>Incomplete</Other></Field>
                    <Field><Rally>Cannot Reproduce</Rally> <Other>Cannot Reproduce</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Status</FieldName>
                <Mappings>
                    <Field><Rally>Submitted</Rally> <Other>Open</Other></Field>
                    <Field><Rally>Open</Rally>      <Other>In Progress</Other></Field>
                    <Field><Rally>Reopened</Rally>  <Other>Reopened</Other></Field>
                    <Field><Rally>Fixed</Rally>     <Other>Resolved</Other></Field>
                    <Field><Rally>Closed</Rally>    <Other>Closed</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

            <!--  enable this for experimentation...
            <JiraHTMLFieldHandler>
               <Field>Description</Field>
            </JiraHTMLFieldHandler>
            -->

            <OtherEnumFieldHandler>
                <FieldName>Severity</FieldName>
                <Mappings>
                    <Field><Rally>Crash/Data Loss</Rally> <Other>Critical</Other></Field>
                    <Field><Rally>5-Urgent High</Rally>   <Other>Severe</Other></Field>
                    <Field><Rally>Major Problem</Rally>   <Other>Major</Other></Field>
                    <Field><Rally>Minor Problem</Rally>   <Other>Minor</Other></Field>
                    <Field><Rally>Cosmetic</Rally>        <Other>Cosmetic</Other></Field>
                    <Field><Rally>None</Rally>            <Other>Trivial</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>

<!-- this user field hander just for experimenting with Jira 4.x testing
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>
 end of user field handlers -->

        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"


  JIRA_REST_WITH_COPY_AND_UPDATE_SELECTORS = "
<config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <ArtifactType>bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally> <Other>Description</Other></Field>
            <Field><Rally>Release</Rally>     <Other>Target Release</Other></Field>
            <Field><Rally>SubmittedBy</Rally> <Other>Reporter</Other></Field>
            <Field><Rally>Owner</Rally>       <Other>Assignee</Other></Field>
        </FieldMapping>
        <OtherFieldHandlers>
            <OtherUserFieldHandler>
                <FieldName>Assignee</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>

            <OtherUserFieldHandler>
                <FieldName>Reporter</FieldName>
                <Domain>rallydev.com</Domain>
            </OtherUserFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</config>"

  JIRA_VERSIONS_FIELDS_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/simplified_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>          <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally>   <Other>Description</Other></Field>
            <Field><Rally>FoundInBuild</Rally>  <Other>Affects Version/s</Other> </Field>
            <Field><Rally>FixedInBuild</Rally>  <Other>Fix Version/s</Other></Field>
        </FieldMapping>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_CORNER_CASE_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>RW</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/jira_jail_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>          <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally>   <Other>Description</Other></Field>
            <Field><Rally>FoundInBuild</Rally>  <Other>Affects Version/s</Other> </Field>
            <Field><Rally>FixedInBuild</Rally>  <Other>Fix Version/s</Other></Field>
            <Field><Rally>Owner</Rally>         <Other>Assignee</Other></Field>
        </FieldMapping>

        <OtherFieldHandlers>
            <OtherEnumFieldHandler>
                <FieldName>Assignee</FieldName>
                 <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>test_user@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
             </OtherEnumFieldHandler>

            <OtherEnumFieldHandler>
                <FieldName>Reporter</FieldName>
                <Mappings>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>testuser</Other></Field>
                    <Field><Rally>yeti@rallydev.com</Rally> <Other>devuser</Other></Field>
                </Mappings>
            </OtherEnumFieldHandler>
        </OtherFieldHandlers>

    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_COMPONENTS_FIELD_CONFIG_FILE = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
        <CrosslinkUrlField>JiraLink</CrosslinkUrlField>
        <CopySelectors>
           <CopySelector>State = Open</CopySelector>
        </CopySelectors>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <ExternalEndUserIDField>RallyItem</ExternalEndUserIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <CopySelectors>
          <CopySelector>Status != Closed</CopySelector>
        </CopySelectors>
        <UpdateSelectors>
          <UpdateSelector>Priority != Critical</UpdateSelector>
        </UpdateSelectors>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>          <Other>Summary</Other></Field>
            <Field><Rally>Description</Rally>   <Other>Description</Other></Field>
            <Field><Rally>Components</Rally>    <Other>Component/s</Other> </Field>
        </FieldMapping>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_NO_CROSSLINK_CONFIG = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <Project>TST</Project>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>    <Other>Summary</Other></Field>
        </FieldMapping>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_CONFIG_WITH_TIMEOUTS = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <Project>TST</Project>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <OpenTimeout>33</OpenTimeout>
        <ReadTimeout>44</ReadTimeout>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
        </FieldMapping>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  JIRA_CONFIG_WITH_INVALID_TIMEOUTS = "
<Config>
    <RallyConnection>
        #{AC_ACCESS}
        <ArtifactType>Defect</ArtifactType>
        <ExternalIDField>JiraKey</ExternalIDField>
    </RallyConnection>
    <JiraConnection>
        <Url>#{JIRA_SERVER}</Url>
        <User>testuser</User>
        <Password>jiradev</Password>
        <Project>TST</Project>
        <ArtifactType>Bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <OpenTimeout>Alcan Highway</OpenTimeout>
        <ReadTimeout>SixSixOne</ReadTimeout>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
    <Connector>
        <FieldMapping>
            <Field><Rally>Name</Rally>        <Other>Summary</Other></Field>
        </FieldMapping>
    </Connector>
    <ConnectorRunner>
        <Preview>false</Preview>
        <LogLevel>Warning</LogLevel>
        <Services>COPY_JIRA_TO_RALLY, COPY_RALLY_TO_JIRA, UPDATE_RALLY_TO_JIRA</Services>
    </ConnectorRunner>
</Config>"

  ON_DEMAND_JIRA_CONNECTION = "
  <Config>
  <JiraConnection>
        <Url>https://foobar.atlassian.net</Url>
        <User>devuser</User>
        <Password>jiradev</Password>
        <AccountID>123abc456xyz</AccountID>
        <ArtifactType>bug</ArtifactType>
        <ExternalIDField>RallyID</ExternalIDField>
        <CrosslinkUrlField>RallyURL</CrosslinkUrlField>
        <Project>TST</Project>
        <WorkflowFile>configs/jira_workflow.xml</WorkflowFile>
    </JiraConnection>
  </Config>
  "

  def jira_connect(config_file)
    #root = YetiTestUtils::load_xml(config_file).root
    konfab = Konfabulator.new(config_file)
    jira_connection = RallyEIF::WRK::JiraConnection.new(konfab.section("JiraConnection"))
    jira_connection.connect()
    return jira_connection
  end

  DEFAULT_ASSIGNEE = "yeti"

  def make_issue_with_external_id(fields)
    oid = 12345 + rand(1000)
    fields[@jira.external_id_field] = oid.to_s
    return fields
  end

  def create_jira_issue(issue_fields, default_external_id=false, jira=@jira)
    if !issue_fields.has_key?('Summary')
      issue_fields['Summary'] = 'Test issue summary'
    end
    if !issue_fields.has_key?('Assignee')
      issue_fields['Assignee'] = DEFAULT_ASSIGNEE
    end
    if default_external_id == false
      # provide a random Rally defect OID for the external_id_field
      #issue_fields = make_issue_with_external_id(issue_fields)
      oid = 12345 + rand(1000)
      issue_fields[jira.external_id_field] = oid.to_s
    end

    issue = jira.create(issue_fields)
    issue.should_not be_nil
    issue.key.should_not be_nil

    return issue, issue.key
  end

  # this is the original that uses instance var @jira
  # def create_jira_issue(issue_fields, default_external_id=false)
  #   if !issue_fields.has_key?('Summary')
  #     issue_fields['Summary'] = 'Test issue summary'
  #   end
  #   if !issue_fields.has_key?('Assignee')
  #     issue_fields['Assignee'] = DEFAULT_ASSIGNEE
  #   end
  #   if default_external_id == false
  #     # provide a random Rally defect OID for the external_id_field
  #     issue_fields = make_issue_with_external_id(issue_fields)
  #   end
  #
  #   issue = @jira.create(issue_fields)
  #   issue.should_not be_nil
  #   issue.key.should_not be_nil
  #
  #   return issue, issue.key
  # end

  def create_issue(jira_connection, issue_fields)
    if !issue_fields.has_key?('Summary')
      issue_fields['Summary'] = 'Test issue summary'
    end
    if !issue_fields.has_key?('Assignee')
      issue_fields['Assignee'] = DEFAULT_ASSIGNEE
    end

    issue = jira_connection.create(issue_fields)
    issue.should_not be_nil
    issue.key.should_not be_nil

    return issue, issue.key
  end

  def load_xml(config_data)
    #YetiTestUtils::load_xml(config_data, "JiraConnection")
    konfab = Konfabulator.new(config_data)
    konfab.section("JiraConnection")
  end

  def modify_config_data(config, section, new_tag, value, action, ref_tag)
    # given config which is a single string containing all of the '\n' separated lines for a config file,
    #       section which identifies the "major" section of the config where the augment is to take place
    #       new_tag with the name of the new tag which augments the config
    #       value with the content for aug_tag
    #       action -> one of 'before', 'after', 'replace', 'delete'
    #       ref_tag that identifies an existing tag in the target_section for reference
    # use regex to find and then modify the config with new_tag and value in the appropriate location
    # in the string relative to the ref_tag
    return config if config !~ /<#{section}>/

    secregex = Regexp.new(/(<#{section}>)(.*?)(<\/#{section}>).*?\n/m)
    sec_md = secregex.match(config)
    section_content = sec_md[2]

    reftag_regex = Regexp.new(/(<#{ref_tag}>.*?<\/#{ref_tag}>.*?\n)/m)
    tagmd = reftag_regex.match(section_content)
    ref_block = $1

    default_indent = " " * 16
    reftag_line = section_content.split("\n").find {|line| line =~ /<#{ref_tag}>/}
    if reftag_line and reftag_line =~ /^(\s+)/
      indent = $1
    else
      indent = default_indent
    end

    augment = "<%s>%s</%s>" % [new_tag, value, new_tag]

    case action
      when "before"
        modified = section_content.sub(reftag_regex, "#{augment}\n#{indent}#{ref_block}")
      when "after"
        modified = section_content.sub(reftag_regex, "#{ref_block}#{indent}#{augment}\n")
      when "replace"
        modified = section_content.sub(reftag_regex, "#{augment}\n")
      when "delete"
        modified = section_content.sub(reftag_regex, "\n")
      else
        modified = section_content.dup
    end

    modified_section = [sec_md[1], modified, sec_md[3]].join("") + "\n"
    return config.sub(secregex, modified_section)

  end

  module_function :jira_connect, :load_xml, :modify_config_data

  def create_rally_artifact(rally_connection, extra_fields = nil)
    name = Time.now.strftime("%y%m%d%H%M%S") + Time.now.usec.to_s
    fields = {}
    fields[:Name] = name
    if !extra_fields.nil?
      fields.merge!(extra_fields)
    end
    defect = rally_connection.create(fields)
    return [defect, name]
  end


end
