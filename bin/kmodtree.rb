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

require 'optparse'

options = {:fn => "/proc/modules"}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [MODULE]..."

  opts.separator("")
  opts.separator("Options:")

  opts.on("-f", "--filename FILENAME", "the path of modules") do |f|
    options[:fn] = f
  end

  opts.on("-h", "--help", "Show this message") do |h|
    puts opts
    exit
  end
end.parse!(ARGV)

child = Hash.new
IO.foreach(options[:fn]) do |l|
  mod, o1, o2, deps = l.split
  if deps == '-'
    deps = nil
  else
    deps = deps.split(',')
  end
  child[mod] = deps
end
if ARGV.length > 0
  mods = ARGV
else
  mods = child.keys
end

parent = Hash.new
child.each do |k, v|
  next if not v
  v.each do |c|
    if (parent.include?(c))
      parent[c].push(k)
    else
      parent[c] = [k];
    end
  end
end

def print_ascent(parent, m, prefix)
  if (parent.include?(m))
    i = 0
    parent[m].each do |p|
      print prefix
      i = i.next
      if (i == parent[m].length)
        print "`-";
	next_prefix = prefix + "  ";
      else
        print "+-";
	next_prefix = prefix + "| ";
      end
      puts "#{p}"
      print_ascent(parent, p, next_prefix)
    end
  end
end

first = true
mods.each do |m|
  if not child.include?(m)
    puts "#{m} isn't loaded"
    exit 1
  end
  if first
    first = false
  else
    puts
  end
  puts m
  print_ascent(parent, m, "")
end
