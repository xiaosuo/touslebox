#!/usr/bin/env ruby

def left_pad(str, length)
  str = ' ' * [0, length - str.size].max + str
end

rows = []
column_lengths = []
STDIN.each_line do |line|
  columns = line.strip.split
  rows << columns
  column_lengths.fill(0, column_lengths.size, [columns.size - column_lengths.size, 0].max)
  column_lengths = column_lengths.zip(columns.map(&:size)).map{|a, b| [a, b || 0].max}
end

rows.each do |row|
  puts row.zip(column_lengths).map{|column, len| left_pad(column, len)}.join('  ')
end
