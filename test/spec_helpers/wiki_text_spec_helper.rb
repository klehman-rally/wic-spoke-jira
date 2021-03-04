# Copyright 2001-2018 Rally Software Development Corp. All Rights Reserved.
require_relative 'spec_helper'
require_relative "#{File.dirname(__FILE__)}/../../lib/rallyeif/jira/jira_connection/jira_connection"

include RallyEIF::WRK
include YetiTestUtils

module JiraWikiTextSpecHelper
  class JWData
    def self.jira_wiki_text
      return "\
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
    end

    def self.html_text
      return "<ul>\n<li>An item in a bulleted (unordered) list</li>\n<li>Another item in a bulleted list</li>\n</ul>\n<h1>Biggest heading</h1>\n<h2>Bigger heading</h2>\n<h3>Big heading</h3>\n<h4>Normal heading</h4>\n<h5>Small heading</h5>\n<h6>Smallest heading</h6>\n<p><strong>strong</strong><br />\n<em>emphasis</em><br />\n<cite>citation</cite><br />\n<del>deleted</del><br />\n<ins>inserted</ins><br />\n<sup>superscript</sup><br />\n<sub>subscript</sub></p>\n<table>\n<tr>\n<th>Header </th>\n<th>Header </th>\n<th>Header </th>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n</table>"
    end

    def self.jira_wiki_header_text
      return "\
h1. Biggest heading

h2. Bigger heading

h3. Big heading

h4. Normal heading

h5. Small heading

h6. Smallest heading"
    end

    def self.html_header_text
      return "<h1>Biggest heading</h1>\n<h2>Bigger heading</h2>\n<h3>Big heading</h3>\n<h4>Normal heading</h4>\n<h5>Small heading</h5>\n<h6>Smallest heading</h6>"
    end

    def self.jira_wiki_text_effects
      return "\
*strong*
_emphasis_
??citation??
-deleted-
+inserted+
^superscript^
~subscript~"
    end

    def self.html_text_effects
      return "<p><strong>strong</strong><br />\n<em>emphasis</em><br />\n<cite>citation</cite><br />\n<del>deleted</del><br />\n<ins>inserted</ins><br />\n<sup>superscript</sup><br />\n<sub>subscript</sub></p>"
    end

    def self.jira_wiki_lists
      return "\
* An item in a bulleted (unordered) list
* Another item in a bulleted list"
    end

    def self.html_lists
      return "<ul>\n<li>An item in a bulleted (unordered) list</li>\n<li>Another item in a bulleted list</li>\n</ul>"
    end

    def self.jira_wiki_table
      return "\
||Header ||Header ||Header ||
| Cell 1 | Cell 2 | Cell 3 |
| Cell 1 | Cell 2 | Cell 3 |"
    end

    def self.html_table
      return "<table>\n<tr>\n<th>Header </th>\n<th>Header </th>\n<th>Header </th>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n<tr>\n<td> Cell 1 </td>\n<td> Cell 2 </td>\n<td> Cell 3 </td>\n</tr>\n</table>"
    end

    def self.jira_wiki_table_two_readable
      return "\
||mfr||year||country||
|mercedes|1965|germany|
|toyota|2003|japan|
|ford|2010|usa|\n"
    end

    def self.jira_wiki_table_two
      return "||mfr||year||country||\n|mercedes|1965|germany|\n|toyota|2003|japan|\n|ford|2010|usa|"
    end

    def self.html_table_two
      return "<table>\n<tr>\n<th>mfr</th>\n<th>year</th>\n<th>country</th>\n</tr>\n<tr>\n<td>mercedes</td>\n<td>1965</td>\n<td>germany</td>\n</tr>\n<tr>\n<td>toyota</td>\n<td>2003</td>\n<td>japan</td>\n</tr>\n<tr>\n<td>ford</td>\n<td>2010</td>\n<td>usa</td>\n</tr>\n</table>"
    end

    def self.jira_text_breaks
      return "\
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
    end

    def self.html_breaks
      return "<p>line test marker one</p>\n<p>line test marker two<br />\n\\<br />\nline test marker three<hr>line test marker four<br />\n<del>-</del><br />\nline test marker five<br />\n&#8212;<br />\nline test marker six</p>"
    end

    def self.jira_wiki_image_links
      return "\
!http://www.host.com/image.gif!
!attached-image.gif!
!image.jpg|thumbnail!
!image.gif|align=right, vspace=4!"
    end

    def self.html_image_links
      return "<p><img src=\"http://www.host.com/image.gif\" alt=\"\" /><br />\n<img src=\"attached-image.gif\" alt=\"\" /><br />\n<img src=\"image.jpg|thumbnail\" alt=\"\" /><br />\n!image.gif|align=right, vspace=4!</p>"
    end

    def self.jira_wiki_monospaced
      return "{{monospaced}}"
    end

    def self.html_monospaced
      return "<p><code>monospaced</code></p>"
    end

    def self.jira_wiki_blockquote
      return "bq. some quoted text"
    end

    def self.html_blockquote
      return "<blockquote>\n<p>some quoted text</p>\n</blockquote>"
    end

    def self.jira_wiki_links
      return "\
[http://www.rallydev.com]
[Rally Software Development Corp|http://www.rallydev.com]
[mailto:connectors@rallydev.com]"
    end

    def self.html_links
      return "<p><a href=\"http://www.rallydev.com\">http://www.rallydev.com</a><br />\n<a href=\"http://www.rallydev.com\">Rally Software Development Corp</a><br />\n<a href=\"mailto:connectors@rallydev.com\">mailto:connectors@rallydev.com</a></p>"
    end

  end

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

end  # module JiraWikiTextSpecHelper


