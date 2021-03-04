# Copyright 2001-2018 CA Technologies. All Rights Reserved.
module RallyEIF
  module WRK
    module Utils
      module XmlSchemas

        def self.jira
          %q[
<?xml version="1.0" encoding="ISO-8859-1" ?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xs:simpleType name="nonEmptyString">
    <xs:restriction base="xs:string">
    <xs:minLength value="1"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="digitsString">
    <xs:restriction base="xs:string">
    <xs:pattern value="\d+" />
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="httpURI">
    <xs:restriction base="xs:anyURI">
    <xs:minLength value="1"/>
    </xs:restriction>
  </xs:simpleType>

  <xs:simpleType name="httpURI_with_port">
    <xs:restriction base="xs:anyURI">
    <xs:pattern value="(http|https)://.*:\d*(/.*)?" />
    </xs:restriction>
  </xs:simpleType>

<xs:element name="Config">
<xs:complexType>
<xs:sequence>

<!-- === Start RallyConnection ============================ -->
<xs:element name="RallyConnection" minOccurs="1" maxOccurs="1">
<xs:complexType>
  <xs:all>

    <xs:element type="httpURI" name="Url" minOccurs="1" maxOccurs="1"/>
    <xs:element type="nonEmptyString" name="WorkspaceName" minOccurs="1" maxOccurs="1"/>
    <xs:element name="Projects" minOccurs="1" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element type="nonEmptyString" name="Project" minOccurs="1" maxOccurs="unbounded"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element type="nonEmptyString" name="User" minOccurs="1" maxOccurs="1"/>
    <xs:element type="nonEmptyString" name="Password" minOccurs="1" maxOccurs="1"/>
    <xs:element type="nonEmptyString" name="ArtifactType" minOccurs="1" maxOccurs="1"/>
    <xs:element type="nonEmptyString" name="ExternalIDField" minOccurs="1" maxOccurs="1"/>

    <xs:element type="xs:string" name="SuppressDeprecationWarning" minOccurs="0" maxOccurs="1"/>
    <xs:element type="xs:string" name="IncludeSubProjects" minOccurs="0" maxOccurs="1"/>
    <xs:element type="nonEmptyString" name="CrosslinkUrlField" minOccurs="0" maxOccurs="1"/>
    <xs:element name="CopySelectors" minOccurs="0" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element type="nonEmptyString" name="CopySelector" minOccurs="0" maxOccurs="unbounded"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="UpdateSelectors" minOccurs="0" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element type="nonEmptyString" name="UpdateSelector" minOccurs="0" maxOccurs="unbounded"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element type="nonEmptyString" name="PreCopyFilters" minOccurs="0" maxOccurs="1"/>

    <xs:element name="FieldDefaults" minOccurs="0" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element name="Field" maxOccurs="unbounded" minOccurs="1">
            <xs:complexType>
              <xs:sequence>
                <xs:element type="nonEmptyString" name="Name"/>
                <xs:element type="nonEmptyString" name="Default"/>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:sequence>
      </xs:complexType>
    </xs:element>

  </xs:all>
</xs:complexType>
</xs:element>
<!-- === Stop RallyConnection ============================= -->


<!-- === Start JiraConnection ============================ -->
<xs:element name="JiraConnection" minOccurs="1" maxOccurs="1">
<xs:complexType>
  <xs:all>

    <xs:element type="httpURI_with_port" name="Url" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="User" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="Password" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="ArtifactType" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="Project" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="ExternalIDField" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="ExternalEndUserIDField" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="CrosslinkUrlField" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="WorkflowFile" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="FinalStatus" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="ProxyURL" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="ProxyUser" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="ProxyPassword" minOccurs="0"/>
    <xs:element type="digitsString" name="OpenTimeout" minOccurs="0"/>
    <xs:element type="digitsString" name="ReadTimeout" minOccurs="0"/>

    <xs:element name="CopySelectors" minOccurs="0">
      <xs:complexType>
        <xs:sequence>
          <xs:element type="nonEmptyString" name="CopySelector" minOccurs="0" maxOccurs="unbounded"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>

    <xs:element name="UpdateSelectors" minOccurs="0">
      <xs:complexType>
        <xs:sequence>
          <xs:element type="nonEmptyString" name="UpdateSelector" minOccurs="0" maxOccurs="unbounded"/>
        </xs:sequence>
      </xs:complexType>
    </xs:element>

    <xs:element name="FieldDefaults" minOccurs="0" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element name="Field" maxOccurs="unbounded" minOccurs="1">
            <xs:complexType>
              <xs:sequence>
                <xs:element type="nonEmptyString" name="Name"/>
                <xs:element type="nonEmptyString" name="Default"/>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:sequence>
      </xs:complexType>
    </xs:element>

  </xs:all>
</xs:complexType>
</xs:element>
<!-- === Stop JiraConnection ============================= -->


<!-- === Start Connector ============================ -->
<xs:element name="Connector" minOccurs="1" maxOccurs="1">
<xs:complexType>
  <xs:all>
    <xs:element name="FieldMapping" minOccurs="1" maxOccurs="1">
      <xs:complexType>
        <xs:sequence>
          <xs:element name="Field" maxOccurs="unbounded" minOccurs="0">
            <xs:complexType>
              <xs:sequence>
                <xs:element type="nonEmptyString" name="Rally"/>
                <xs:element type="nonEmptyString" name="Other"/>
                <xs:element type="nonEmptyString" name="Direction" minOccurs="0"/>
              </xs:sequence>
            </xs:complexType>
          </xs:element>
        </xs:sequence>
      </xs:complexType>
    </xs:element>
    <xs:element name="RallyFieldHandlers" minOccurs="0" maxOccurs="1">
    </xs:element>
    <xs:element name="OtherFieldHandlers" minOccurs="0" maxOccurs="1">
    </xs:element>
    <xs:element name="RelatedObjectLinkers" minOccurs="0" maxOccurs="1">

     <xs:complexType>
        <xs:all>
          <xs:element name="RallyAttachmentLinker"  minOccurs="0" maxOccurs="1"/>
          <xs:element name="RallyJiraCommentLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="QCReqtoRallyTestWorkProductLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="QCScriptToRallyLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="QCToRallyTestStepLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="RallyStoryFieldForQCReq" minOccurs="0" maxOccurs="1"/>
          <xs:element name="RallyToQCTestReqLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="RallyToQCTestStepLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="RallyToQCTSTestIDinPlanLinker" minOccurs="0" maxOccurs="1"/>
          <xs:element name="StoryToParentLinker" minOccurs="0" maxOccurs="1"/>
        </xs:all>
     </xs:complexType>

    </xs:element>
  </xs:all>
</xs:complexType>
</xs:element>
<!-- === Stop Connector ============================= -->


<!-- === Start ConnectorRunner ============================ -->
<xs:element name="ConnectorRunner" minOccurs="1" maxOccurs="1">
<xs:complexType>
  <xs:all>
    <xs:element type="nonEmptyString" name="Preview" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="LogLevel" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="Services" minOccurs="1"/>
    <xs:element type="nonEmptyString" name="PostServiceActions" minOccurs="0"/>
    <xs:element type="nonEmptyString" name="Emailer" minOccurs="0"/>
  </xs:all>
</xs:complexType>
</xs:element>
<!-- === Stop ConnectorRunner ============================= -->


</xs:sequence>
</xs:complexType>
</xs:element>
<xs:element name="config" substitutionGroup="Config"/>
</xs:schema>
]
        end


      end
    end
  end
end
