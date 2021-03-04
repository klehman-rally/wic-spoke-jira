# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
# RedCloth deprecated in Ruby 2.0.0 Windows shared object
spec_root = File.absolute_path(File::join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(spec_root)
require 'spec_helpers/jira_spec_helper'
require 'rspec'

include YetiTestUtils
include JiraSpecHelper
include RallyEIF::WRK::FieldHandlers

class MockJiraArtifact
  attr_accessor :elements

  def initialize(desc)
    @elements = {}
    @elements['Description'] = desc
  end

  def [] (key)
    return @elements[key]
  end

  def get_value(artifact, field_name)
    return artifact[field_name]
  end
end

class MockJiraClient

  def getGroup(group_name)
    return MockJiraRemoteGroup.new(group_name)
  end
end

class JiraTestConnection < JiraConnection
  attr_accessor :jira

  def initialize()
    super()
    @jira = MockJiraClient.new
  end

  def get_value(artifact, field_name)
    return artifact[field_name]
  end

  def name()
    return ""
  end

  def version()
    return ""
  end

  def connect
  end
end

describe 'Jira Wiki Text Field Handler Tests' do

  jira_wiki_text_field_handler_req = "
    <JiraWikiTextFieldHandler>
      <FieldName>Description</FieldName>
    </JiraWikiTextFieldHandler>"

=begin
** Second Level
** Second Level Items
*** Third level
{{monospaced}}
bq. Some block quoted text
=end

  jira_wiki_header_text = "\
h1. Biggest heading

h2. Bigger heading

h3. Big heading

h4. Normal heading

h5. Small heading

h6. Smallest heading"

  html_header_text = "<h1>Biggest heading</h1>\n<h2>Bigger heading</h2>\n<h3>Big heading</h3>\n<h4>Normal heading</h4>\n<h5>Small heading</h5>\n<h6>Smallest heading</h6>"

  jira_wiki_text_effects = "\
*strong*
_emphasis_
??citation??
-deleted-
+inserted+
^superscript^
~subscript~"

  html_text_effects = "<p><strong>strong</strong><br />\n<em>emphasis</em><br />\n<cite>citation</cite><br />\n<del>deleted</del><br />\n<ins>inserted</ins><br />\n<sup>superscript</sup><br />\n<sub>subscript</sub></p>"

  jira_wiki_lists = "\
* An item in a bulleted (unordered) list
* Another item in a bulleted list"

  html_lists = "<ul>\n<li>An item in a bulleted (unordered) list</li>\n<li>Another item in a bulleted list</li>\n</ul>"

  jira_wiki_table = "\
||Header ||Header ||Header ||
| Cell 1 | Cell 2 | Cell 3 |
| Cell 1 | Cell 2 | Cell 3 |"

  html_table = "<table>\n<tr>\n<th>Header </th>\n<th>Header </th>\n<th>Header </th>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n</table>"

  jira_wiki_table_two = "||mfr||year||country||
|mercedes|1965|germany|
|toyota|2003|japan|
|ford|2010|usa|\n"

  jira_wiki_table_two = "||mfr||year||country||\n|mercedes|1965|germany|\n|toyota|2003|japan|\n|ford|2010|usa|"

  html_table_two = "<table>\n<tr>\n<th>mfr</th>\n<th>year</th>\n<th>country</th>\n</tr>\n<tr>\n<td>mercedes</td>\n<td>1965</td>\n<td>germany</td>\n</tr>\n<tr>\n<td>toyota</td>\n<td>2003</td>\n<td>japan</td>\n</tr>\n<tr>\n<td>ford</td>\n<td>2010</td>\n<td>usa</td>\n</tr>\n</table>"

  jira_text_breaks = "\
line test marker one

line test marker two
\\
line test marker three
----
line test marker four
---
line test marker five
--
line test marker six"

  html_breaks = "<p>line test marker one</p>\n<p>line test marker two<br />\n\\<br />\nline test marker three<hr>line test marker four<br />\n<del>-</del><br />\nline test marker five<br />\n&#8212;<br />\nline test marker six</p>"

  jira_wiki_image_links = "\
!http://www.host.com/image.gif!
!attached-image.gif!
!image.jpg|thumbnail!
!image.gif|align=right, vspace=4!"

  html_image_links = "<p><img src=\"http://www.host.com/image.gif\" alt=\"\" /><br />\n<img src=\"attached-image.gif\" alt=\"\" /><br />\n<img src=\"image.jpg|thumbnail\" alt=\"\" /><br />\n!image.gif|align=right, vspace=4!</p>"

  jira_wiki_monospaced = "{{monospaced}}"
  html_monospaced = "<p><code>monospaced</code></p>"

  jira_wiki_blockquote = "bq. some quoted text"
  html_blockquote = "<blockquote>\n<p>some quoted text</p>\n</blockquote>"

  jira_wiki_links = "\
[http://www.rallydev.com]
[Rally Software Development Corp|http://www.rallydev.com]
[mailto:connectors@rallydev.com]"

  html_links = "<p><a href=\"http://www.rallydev.com\">http://www.rallydev.com</a><br />\n<a href=\"http://www.rallydev.com\">Rally Software Development Corp</a><br />\n<a href=\"mailto:connectors@rallydev.com\">mailto:connectors@rallydev.com</a></p>"

  jira_wiki_text = "\
* An item in a bulleted (unordered) list
* Another item in a bulleted list

h1. Biggest heading

h2. Bigger heading

h3. Big heading

h4. Normal heading

h5. Small heading

h6. Smallest heading

*strong*
_emphasis_
??citation??
-deleted-
+inserted+
^superscript^
~subscript~

||Header ||Header ||Header ||
| Cell 1 | Cell 2 | Cell 3 |
| Cell 1 | Cell 2 | Cell 3 |"

#<tr><td>Cell 1</td><td>Cell 2</td><td>Cell 3</td></tr>
#<tr><th>Header</th><th>Header</th><th>Header</th></tr>

  html_text = "<ul>\n<li>An item in a bulleted (unordered) list</li>\n<li>Another item in a bulleted list</li>\n</ul>\n<h1>Biggest heading</h1>\n<h2>Bigger heading</h2>\n<h3>Big heading</h3>\n<h4>Normal heading</h4>\n<h5>Small heading</h5>\n<h6>Smallest heading</h6>\n<p><strong>strong</strong><br />\n<em>emphasis</em><br />\n<cite>citation</cite><br />\n<del>deleted</del><br />\n<ins>inserted</ins><br />\n<sup>superscript</sup><br />\n<sub>subscript</sub></p>\n<table>\n<tr>\n<th>Header </th>\n<th>Header </th>\n<th>Header </th>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n</table>"

  before(:each) do
    @jira = JiraTestConnection.new
    @jira.connect()
    @dfh = JiraWikiTextFieldHandler.new
    @dfh.read_config({'FieldName' => :Description})
    @dfh.connection = @jira
  end

  # 1
  it "Jira Wiki Text Handler should set field value to Description" do
    #puts "got into first Jira Wiki Text Handler spec test"
    ufh = JiraWikiTextFieldHandler.new
    ufh.read_config({'FieldName' => :Description})
    ufh.field_name.should == :Description
  end

  # 2
  it "Jira Wiki Text Field Handler transform_in should return empty for empty input set" do
    #root = REXML::Document.new(jira_wiki_text_field_handler_req).root
    @jira = JiraTestConnection.new
    @jira.connect()
    ufh = JiraWikiTextFieldHandler.new
    ufh.read_config({'FieldName' => :Description})
    ufh.connection = @jira

    artifact = MockJiraArtifact.new("")
    ufh.transform_out(artifact).should == ""

    artifact = MockJiraArtifact.new("foobar")
    ufh.transform_out(artifact).should == "<p>foobar</p>"
  end

  # 3
  it "Jira Wiki Text Field Handler transform_in should return html from wiki text" do
    #root = REXML::Document.new(jira_wiki_text_field_handler_req).root
    @jira = JiraTestConnection.new
    @jira.connect()
    ufh = JiraWikiTextFieldHandler.new
    ufh.read_config({'FieldName' => :Description})
    ufh.connection = @jira

    artifact = MockJiraArtifact.new(jira_wiki_text)
    ufh.transform_out(artifact).should == html_text
  end

  # 4
  it "Jira Wiki Text Field Handler transform_out should return wiki text from html" do
    #root = REXML::Document.new(jira_wiki_text_field_handler_req).root
    @jira = JiraTestConnection.new
    @jira.connect()
    ufh = JiraWikiTextFieldHandler.new
    ufh.read_config({'FieldName' => :Description})
    ufh.connection = @jira

    ufh.transform_in(html_text).should == jira_wiki_text
  end

  ## transform_in: Rally to Jira
  ## transform_out: Jira to Rally

  # 5
  it "should transform_in headings" do
    @dfh.transform_in(html_header_text).should == jira_wiki_header_text

  end

  # 6
  it "should transform_out headings" do
    artifact = MockJiraArtifact.new(jira_wiki_header_text)
    @dfh.transform_out(artifact).should == html_header_text
  end

  # 7
  it "should transform_in text_effects" do
    @dfh.transform_in(html_text_effects).should == jira_wiki_text_effects
  end

  # 8
  it "should transform_out text_effects" do
    artifact = MockJiraArtifact.new(jira_wiki_text_effects)
    @dfh.transform_out(artifact).should == html_text_effects
  end

  # 9
  it "should transform_in lists" do
    @dfh.transform_in(html_lists).should == jira_wiki_lists
  end

  # 10
  it "should transform_out lists" do
    artifact = MockJiraArtifact.new(jira_wiki_lists)
    @dfh.transform_out(artifact).should == html_lists
  end

  # 11
  it "should transform_in table" do
    @dfh.transform_in(html_table).should == jira_wiki_table
  end

  # 12
  it "should transform_out table" do
    artifact = MockJiraArtifact.new(jira_wiki_table)
    @dfh.transform_out(artifact).should == html_table
  end

  # 13
  it "should transform_in table two" do
    @dfh.transform_in(html_table_two).should == jira_wiki_table_two
  end

  # 14
  it "should transform_out table two" do
    artifact = MockJiraArtifact.new(jira_wiki_table_two)
    @dfh.transform_out(artifact).should == html_table_two
  end

  # 15
  it "should transform_in text breaks" do
    @dfh.transform_in(html_breaks).should == jira_text_breaks
  end

  # 16
  it "should transform_out text breaks" do
    artifact = MockJiraArtifact.new(jira_text_breaks)
    @dfh.transform_out(artifact).should == html_breaks
  end

  # 17
  it "should transform_in image links" do
    @dfh.transform_in(html_image_links).should == jira_wiki_image_links
  end

  # 18
  it "should transform_out image links" do
    artifact = MockJiraArtifact.new(jira_wiki_image_links)
    @dfh.transform_out(artifact).should == html_image_links
  end

  # 19
  it "should transform_in code to monospaced" do
    @dfh.transform_in(html_monospaced).should == jira_wiki_monospaced
  end

  # 20
  it "should transform_out monospaced to code" do
    artifact = MockJiraArtifact.new(jira_wiki_monospaced)
    @dfh.transform_out(artifact).should == html_monospaced
  end

  # 21
  it "should transform_in blockquote to bq." do
    @dfh.transform_in(html_blockquote).should == jira_wiki_blockquote
  end

  # 22
  it "should transform_out bq. to blockquote" do
    artifact = MockJiraArtifact.new(jira_wiki_blockquote)
    @dfh.transform_out(artifact).should == html_blockquote
  end

  # 23
  it "should transform_in <a href='target'></a> to [target]" do
    @dfh.transform_in(html_links).should == jira_wiki_links
  end

  # 24
  it "should transform_out [target] to <a href='target'></a>" do
    artifact = MockJiraArtifact.new(jira_wiki_links)
    @dfh.transform_out(artifact).should == html_links
  end

end
