#!/bin/env ruby
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

if ARGV.length != 1 and ARGV.length != 2
  puts "Usage: #{$0} filename [module]"
  exit 1
end
fn = ARGV[0]
if ARGV.length == 2
  target = ARGV[1]
else
  target = nil
end

child = Hash.new
IO.foreach(fn) do |l|
  mod, o1, o2, deps = l.split
  if deps == '-'
    deps = nil
  else
    deps = deps.split(',')
  end
  child[mod] = deps
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

if target
  if not child.include?(target)
    puts "#{target} isn't loaded"
    exit 1
  end
  
  puts target
  print_ascent(parent, target, "")
else
  first = true
  child.each_key do |m|
    if first
      first = false
    else
      puts
    end
    puts m
    print_ascent(parent, m, "")
  end
end
