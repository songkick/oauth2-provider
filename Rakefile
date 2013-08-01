require 'rubygems'
require 'bundler/setup'
require 'appraisal'

task :default => :spec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new('spec') do |t|
  t.rspec_opts = ['-c', '-r ./spec/spec_helper.rb']
  t.pattern = 'spec/**/*_spec.rb'
end

