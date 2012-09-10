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

def get_nic_stat
  skip = 2
  stats = Hash.new
  ifindex = 0
  titles = ["name",
            "rx-bytes", "rx-packets", "rx-errs", "rx-drop", "rx-fifo",
            "rx-frame", "rx-compressed", "rx-multicast",
            "tx-bytes", "tx-packets", "tx-errs", "tx-drop", "tx-fifo",
            "tx-frame", "tx-compressed", "tx-multicast"]
  IO.foreach("/proc/net/dev") do |l|
    if skip > 0
      skip -= 1
      next
    end
    ti = 0
    l.split.each do |f|
      f.strip!
      if ti == 0
        f.chomp!(':')
        ifindex = IO.read("/sys/class/net/#{f}/ifindex").strip.to_i
        stats[ifindex] = Hash.new
        stats[ifindex]["name"] = f
        stats[ifindex]["rx"] = Hash.new
        stats[ifindex]["tx"] = Hash.new
      else
        xx,t = titles[ti].split("-")
        stats[ifindex][xx][t] = f.to_i
      end
      ti += 1
    end
  end
  stats
end

def pretty_print(num)
  units = ["", "k", "M", "G", "T"]
  unit_i = 0
  while num > 1000
    num /= 1000
    unit_i += 1
  end
  if unit_i >= units.length
    puts "number overflow"
    exit 1
  end
  unit = units[unit_i]
  if (unit.length > 0)
    fmt = "%6"
  else
    fmt = "%7"
  end
  if (num >= 100)
    printf(fmt + "d%s|", num, unit)
  elsif (num >= 10)
    printf(fmt + ".1f%s|", num, unit)
  elsif (num >= 1)
    printf(fmt + ".2f%s|", num, unit)
  elsif (num >= 0.001)
    printf(fmt + ".3f%s|", num, unit)
  else
    printf(fmt + "d%s|", num, unit)
  end
end

options = {:nic => nil, :delay => 3, :count => -1}

opt_pasr = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] [delay [count]]"

  opts.separator("")
  opts.separator("Options:")

  opts.on("-i", "--nic NIC", "NIC name") do |i|
    options[:nic] = i
  end

  opts.on("-h", "--help", "Show this message") do |h|
    puts opts
    exit
  end
end
opt_pasr.parse!(ARGV)
if ARGV.length > 0
  options[:delay] = ARGV[0].to_i
  if options[:delay] <= 0
    puts "invalid delay: #{options[:delay]}"
    exit 1
  end
  if ARGV.length > 1
    if ARGV.length == 2
      options[:count] = ARGV[1].to_i
    else
      puts opt_pasr
      exit 1
    end
  end
end

last_nic_stat = get_nic_stat
puts "+----------------+-----------------------+-----------------------+"
puts "|                |          RX           |          TX           |"
puts "|      NIC       +-------+-------+-------+-------+-------+-------+"
puts "|                |  bps  |  pps  | drop  |  bps  |  pps  | drop  |"
puts "+----------------+-------+-------+-------+-------+-------+-------+"
while true
  sleep(options[:delay])
  nic_stat = get_nic_stat
  nic_stat.each do |i, s|
    next if options[:nic] and options[:nic] != s["name"]
    printf("|%16s|", s["name"])
    ["rx", "tx"].each do |xx|
      ["bytes", "packets", "drop"].each do |t|
        n = s[xx][t]
        if last_nic_stat.include?(i) and last_nic_stat[i][xx][t] <= n
          r = n - last_nic_stat[i][xx][t]
	else
	  r = n
	end
	r /= options[:delay].to_f
	r *= 8 if t == "bytes"
	pretty_print(r)
      end
    end
    puts
  end
  if options[:count] > 0
    options[:count] = options[:count] - 1
    break if options[:count] == 0
  end
  last_nic_stat = nic_stat
end
