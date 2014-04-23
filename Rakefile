# Author: cary@rightscale.com
# Copyright 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'

  task :default => :spec

  desc "Run all unit tests in spec directory"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/**/*_spec.rb'
  end

  desc "Run all integration tests in spec directory"
  RSpec::Core::RakeTask.new(:test) do |t|
    t.pattern = 'test/**/*_test.rb'
  end

rescue LoadError
  STDERR.puts "\n*** RSpec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end

desc "Create a tarball for non-gem distribution"
task :tarball do |t|
  version = File.open("VERSION", "r") { |f| f.read }
  filename = "image_optimize_#{version}.tar"
  puts "Creating tarball #{filename}"
  puts  `mkdir ./pkg ; tar cvf pkg/image_optimize-#{version}.tar bin/ lib/ VERSION Gemfile Gemfile.lock`
  puts "success!"
end