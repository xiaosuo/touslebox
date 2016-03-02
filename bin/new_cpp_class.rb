#!/usr/bin/env ruby
#

require 'time'

def file_set_contents(path, contents)
  if File.exists?(path)
    puts "#{path} exists"
    exit 1
  end
  File.open(path, 'w'){|f| f.write(contents)}
end

if ARGV.size != 1
  puts "Usage: #$0 class"
  exit 1
end

namespace = File.basename(`git rev-parse --show-toplevel`.strip)

klass = ARGV[0]
names = klass.scan(/[A-Z][a-z0-9]*/)
if names.join != klass
  puts "Invalid class name"
  exit 1
end
filename = names.map{|x| x.downcase}.join('_')

guard = filename.upcase + "_H_"
content =<<EOF
// Copyright #{Date.today.year} #{`git config user.name`.strip} <#{`git config user.email`.strip}>

#ifndef #{guard}
#define #{guard}

namespace #{namespace} {

class #{klass} {
 public:
  #{klass}() {}
  virtual ~#{klass}() {}

  #{klass}(const #{klass} &) = delete;
  #{klass}& operator=(const #{klass} &) = delete;

 private:
};

}  // namespace #{namespace}

#endif  // #{guard}
EOF
file_set_contents(filename + '.h', content)

content =<<EOF
// Copyright #{Date.today.year} #{`git config user.name`.strip} <#{`git config user.email`.strip}>

#include <#{filename + '.h'}>

namespace #{namespace} {

}  // namespace #{namespace}
EOF
file_set_contents(filename + '.cc', content)

content =<<EOF
// Copyright #{Date.today.year} #{`git config user.name`.strip} <#{`git config user.email`.strip}>

#include <#{filename + '.h'}>

#include <gtest/gtest.h>

namespace #{namespace} {

TEST(#{klass}, Test01) {
}

}  // namespace #{namespace}
EOF
file_set_contents(filename + '_test.cc', content)
