#!/usr/bin/env ruby
#

require 'net/ssh'
require 'net/ssh/krb'
require 'logger'

App = Struct.new(:args, :cwd)

$logger = Logger.new(STDERR)

def ssh_stdout(ssh, cmd)
  output = ''
  ssh.exec!(cmd) do |ch, type, data|
    output << data if type == :stdout
  end
  output.split("\n")
end

def get_remote_apps(remote_ip, local_ip, local_port)
  Net::SSH.start(remote_ip, ENV['USER'],
                 {:auth_methods => ['gssapi-with-mic', 'publickey']}) do |ssh|
    cmd = "ss -ntp dport = :#{local_port} and dst #{local_ip}"
    lines = ssh_stdout(ssh, cmd)
    if lines.size() < 2
      $logger.warn("Failed to get apps from #{remote_ip}")
      return []
    end
    lines.shift
    pids = []
    lines.each do |l|
      fields = l.split(/\s+/, 6)
      next if fields.size() < 6
      users = fields[5]
      next unless users.start_with?('users:(') and users.end_with?(')')
      users[7...-1].scan(/\("[^"]*",(\d+),(\d+)\)/) do |m|
        pids << m[0].to_i
      end
      users[7...-1].scan(/\("[^"]*",pid=(\d+),fd=(\d+)\)/) do |m|
        pids << m[0].to_i
      end
    end
    apps = []
    pids.uniq.each do |pid|
      lines = ssh_stdout(ssh, "ps -o args -p #{pid}")
      next if lines.size() < 2
      args = lines[1]
      lines = ssh_stdout(ssh, "readlink /proc/#{pid}/cwd")
      next if lines.empty?
      cwd = lines[0]
      $logger.info("get app(#{args}, #{cwd}) from #{remote_ip}")
      apps << App.new(args, cwd)
    end
    return apps
  end
end

if ARGV.size < 2
  puts "Usage: #$0 host port limit"
  exit 1
end
host, port, limit = ARGV
limit &&= limit.to_i

apps = []
Net::SSH.start(host, ENV['USER'],
               {:auth_methods => ['gssapi-with-mic', 'publickey']}) do |ssh|
  lines = ssh_stdout(ssh, "ss -nt sport = :#{port}")
  next if lines.size < 2
  lines.shift
  lines.map do |l|
    ip_port = l.split[4]
    ip_port = ip_port[7..-1] if ip_port.start_with?('::ffff:')
    ip_port.split(':')[0]
  end.uniq.shuffle.each do |remote_ip|
    $logger.info("try to get apps from #{remote_ip}")
    apps += get_remote_apps(remote_ip, host, port)
    break if limit && apps.size() > limit
  end
end

puts apps.uniq
