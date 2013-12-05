#!/usr/bin/env ruby

def get_mem_info()
  data = {}
  IO.foreach('/proc/meminfo') do |line|
    label, value = line.split(/\s*:\s*/)
    number, unit = value.split(/\s+/)
    number = number.to_i
    number *= 1024 if unit == 'kB'
    data[label] = number
  end
  data
end

PURGE_FLAG_PAGECACHE = 1
PURGE_FLAG_DENTRIES_AND_INODES = 2

def purge(flags)
  File.open('/proc/sys/vm/drop_caches', 'w') { |f| f.write(flags.to_s) }
end

ProcInfo = Struct.new(:pid, :exe, :cmdline, :rss)

def mem_top()
  procs = []
  Dir.foreach('/proc') do |dirname|
    next unless dirname =~ /^\d+$/
    proc_info = ProcInfo.new
    proc_info.pid = dirname.to_i
    dirname = File.join('/proc', dirname)
    proc_info.exe = File.readlink(File.join(dirname, 'exe')) rescue nil
    proc_info.cmdline = IO.read(File.join(dirname, 'cmdline')).split(/\0/)
    proc_info.rss = 0
    IO.foreach(File.join(dirname, 'status')) do |line|
      label, value = line.split(/\s*:\s*/)
      next unless label == 'VmRSS'
      number, unit = value.split(/\s+/)
      number = number.to_i
      number *= 1024 if unit == 'kB'
      proc_info.rss = number
      break
    end
    procs << proc_info
  end
  procs.sort { |a, b| b.rss <=> a.rss }
end

def kill_mem_top()
  procs = mem_top
  procs.each do |proc_info|
    exe = nil
    if proc_info.exe
      exe = proc_info.exe
    elsif proc_info.cmdline and proc_info.cmdline.size > 0
      exe = proc_info.cmdline[0].split(/\s+/)[0]
    else
      next
    end
    next unless exe == '/usr/lib/chromium-browser/chromium-browser'
    cmdline = proc_info.cmdline.reduce { |res, i| res + ' ' + i }
    next unless cmdline =~ /--type=renderer/
    puts "#{exe}(#{proc_info.pid})[#{cmdline}] #{proc_info.rss}"
    Process.kill('TERM', proc_info.pid)
    break
  end
end

def main()
  while true
    mem_info = get_mem_info
    free = mem_info['MemFree'] + mem_info['Cached'] + mem_info['Buffers']
    total = mem_info['MemTotal']
    usage = (total - free).to_f / total
    if usage >= 0.8
      `sync`
      purge(PURGE_FLAG_PAGECACHE | PURGE_FLAG_DENTRIES_AND_INODES)
      kill_mem_top
    end
    sleep 3
  end
end

if __FILE__ == $0
  main
end
