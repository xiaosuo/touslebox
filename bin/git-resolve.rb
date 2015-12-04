#!/usr/bin/env ruby

require 'readline'
require 'fileutils'

files=[]
`git status -s`.split(/\n/).each do |l|
  s, f = l.split
  next if s == 'M' || s == '??'
  files << f
end

def confirm(msg)
  while l = Readline.readline("\033[33m#{msg}: y/N > \033[0m").strip
    case l.downcase
    when 'y', 'yes'
      return true
    when 'n', 'no'
      return false
    end
  end
  return false
end

def choose(msg, options, default)
  while l = Readline.readline("\033[33m#{msg}: #{options.join('/')} > \033[0m").strip
    return l if options.include?(l)
  end
  default
end

def merge(file)
  clean = true
  puts
  puts "\033[33mMerging #{file}\033[0m"
  FileUtils.cp file, "#{file}.orig"
  merged = []
  f = File.open(file)
  f.each do |l|
    if l =~ /^<<<<<<< HEAD$/
      head = []
      while l = f.gets
        break if l =~ /^=======$/
        head << l
      end
      current = []
      while l = f.gets
        break if l =~ /^>>>>>>> .+$/
        current << l
      end
      end_mark = l
      head.each do |l|
        STDOUT.write("\033[31m-#{l}\033[0m")
      end
      current.each do |l|
        STDOUT.write("\033[32m+#{l}\033[0m")
      end
      case choose("Your option", %w{old new defer}, 'defer')
      when 'old'
        head.each do |l|
          merged << l
        end
      when 'new'
        current.each do |l|
          merged << l
        end
      when 'defer'
        merged << "<<<<<<< HEAD\n"
        head.each do |l|
          merged << l
        end
        merged << "=======\n"
        current.each do |l|
          merged << l
        end
        merged << end_mark
        clean = false
      end
    else
      merged << l
    end
  end
  if confirm("Save #{file}")
    File.open(file, 'w') do |f|
      merged.each do |l|
        f.write(l)
      end
    end
  end
  if clean and confirm("Stage #{file}")
    `git add #{file}`
  end
end

files.each do |f|
  merge(f)
end
