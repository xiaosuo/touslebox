#!/usr/bin/env ruby
#
# Copyright (C) 2012-  Changli Gao <xiaosuo@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

def escape(v)
  v.to_s.gsub(/\\/, '\\\\\\\\').gsub(/'/, '\\\\\'')
end

def _yml2data(yml, indent = 0)
  res = ''
  case yml
  when Array
    n = 0
    yml.each do |i|
      res += ' ' * indent + '{' + "\n"
      indent += 1
      res += ' ' * indent + 'label: \'' + n.to_s + "',\n"
      case i
      when Array, Hash
        res += ' ' * indent + 'children: [' + "\n"
        res += _yml2data(i, indent + 1)
        res += ' ' * indent + '],' + "\n"
      else
        res += _yml2data(i, indent)
      end
      indent -= 1
      res += ' ' * indent + '},' + "\n"
      n += 1
    end
  when Hash
    yml.keys.sort.each do |k|
      v = yml[k]
      res += ' ' * indent + '{' + "\n"
      indent += 1
      res += ' ' * indent + 'label: \'' + escape(k) +  "',\n"
      case v
      when Array, Hash
        res += ' ' * indent + 'children: [' + "\n"
        res += _yml2data(v, indent + 1)
        res += ' ' * indent + '],' + "\n"
      else
        res += _yml2data(v, indent)
      end
      indent -= 1
      res += ' ' * indent + '},' + "\n"
    end
  when String, Fixnum, TrueClass, FalseClass, NilClass
    res += ' ' * indent + 'value: \'' + escape(yml) + "',\n"
  else
    raise ArgumentError, 'invalid YAML'
  end
  res
end

def yml2data(yml, indent = 0)
  res = ' ' * indent + "[\n"
  res += _yml2data(yml, indent + 1)
  res += ' ' * indent + "]\n"
end

template = <<EOF
<!DOCTYPE html>
<html>
 <head>
  <title>The YAML Viewer</title>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
  <script src="http://mbraak.github.com/jqTree/tree.jquery.js"></script>
  <link rel="stylesheet" href="http://mbraak.github.com/jqTree/jqtree.css" type="text/css">
  <style>
   body { background-color: silver }
   .value { background-color: white }
  </style>
 </head>
 <body>
  <div id="index"></div>
 </body>
 <script>
  $(document).ready(function() {
   $('#index').tree({
    data: <%= index %>,
    onCreateLi: function(node, $li) {
     if (node.value != undefined) {
      value = node.value.replace(/&/g, '&amp;').replace(/"/g, '&quot;')
                        .replace(/'/g, '&#39;').replace(/</g, '&lt;')
                        .replace(/>/g, '&gt;');
      $li.find("div").append(':&nbsp;<span class="value">' + value + '</span>');
     }
    }
   });
  });
 </script>
</html>
EOF

require 'yaml'
require 'erb'

if ARGV.length != 1
  puts "#$0 YAML_FILENAME"
  exit(1)
end

all = YAML.load(IO.read(ARGV[0]))
index = yml2data(all)
erb = ERB.new(template, nil, '%')
STDOUT.write(erb.result(binding))
