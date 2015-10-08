#!/usr/bin/env ruby
#

root = 1
if ARGV.size > 0
  root = ARGV[0].to_i
end

tree = {}
tree[root] = {}
flat = {}
flat[root] = tree[root]

q = []
q << root
until q.empty?
  ppid = q.shift
  begin
    pids = IO.read("/proc/#{ppid}/task/#{ppid}/children").strip.split.map(&:to_i)
    q += pids
    pids.each do |pid|
      flat[ppid][pid] = {}
      flat[pid] = flat[ppid][pid]
    end
  rescue
    # some tasks may be missing, ignore them
  end
end

def print_recursive(prefix, children)
  i = 0
  children.each do |k, v|
    if i == children.size - 1
      puts "#{prefix} `--#{k}"
      print_recursive("#{prefix}    ", v)
    else
      puts "#{prefix} |--#{k}"
      print_recursive("#{prefix} |  ", v)
    end
    i += 1
  end
end

puts "#{root}"
print_recursive('', tree[root])
