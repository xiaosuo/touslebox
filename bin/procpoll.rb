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
require 'pathname'

options = {
  :background => false,
  :cmd => nil,
  :exe => nil,
  :interval => 3,
  :log => nil,
  :verbose => false,
}

opt_pasr = OptionParser.new do |opts|
  opts.banner = "Usage: #$0 [options]"

  opts.separator('')
  opts.separator('Options:')

  opts.on('-b', '--background', 'Run as a background daemon') do |b|
    options[:background] = true
  end

  opts.on('-c', '--command COMMAND', 'The command used to start the exe') do |c|
    options[:cmd] = c
  end

  opts.on('-e', '--exe EXE', 'The executable path') do |e|
    options[:exe] = Pathname.new(e).realpath.to_s
  end

  opts.on('-h', '--help', 'Show this message') do |h|
    puts opts
    exit
  end

  opts.on('-i', '--interval INTERVAL',
      'The polling interval by the second, 3 by default') do |i|
    i = i.to_i
    if i <= 0
      puts 'interval must be a positive integer'
      exit(1)
    end
    options[:interval] = i
  end

  opts.on('-l', '--log LOG', 'The log file, STDOUT by default') do |l|
    options[:log] = l
  end

  opts.on('-v', '--verbose', 'Log every poll') do |v|
    options[:verbose] = true
  end
end
opt_pasr.parse!(ARGV)
if ARGV.length > 0
  puts opt_pasr
  exit(1)
end
unless options[:exe]
  puts 'The executable path is required'
  exit(1)
end
unless options[:cmd]
  puts 'The command is required'
  exit(1)
end

if options[:log]
  log = File.new(options[:log], 'a')
else
  log = STDOUT
end

if options[:background]
  exit!(0) if fork
  Process.setsid
  exit!(0) if fork
  Dir.chdir('/')
  File.umask(0)
  STDIN.reopen('/dev/null')
  STDOUT.reopen('/dev/null', 'w')
  STDERR.reopen('/dev/null', 'w')
end

while true
  exist = false
  Dir.foreach('/proc') do |fn|
    next unless fn =~ /\d+/
    begin
      if File.readlink(File.join('/proc', fn, 'exe')) == options[:exe]
        exist = true
        break
      end
    rescue
    end
  end
  if exist
    if options[:verbose]
      ts = Time.new.utc.strftime('%FT%TZ')
      log.puts(ts + ' ' + options[:exe] + ' is running')
    end
  else
    ts = Time.new.utc.strftime('%FT%TZ')
    log.puts(ts + ' ' + options[:exe] + ' has been stopped, so restart it')
    system(options[:cmd])
  end
  sleep options[:interval]
end
