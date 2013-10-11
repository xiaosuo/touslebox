#!/usr/bin/env ruby

# Add .gitkeep to empty directories of a subversion repository.

def walk
  n = 0
  Dir.foreach('.') do |f|
    next if f == '.' || f == '..' || f == '.svn'
    if File.directory?(f)
      Dir.chdir(f)
      walk
      Dir.chdir('..')
    end
    n += 1
  end
  if n == 0
    File.new('.gitkeep', 'w')
  end
end
walk
