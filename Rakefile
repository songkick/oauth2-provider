require "rubygems"

task :default => :spec

require 'rdoc/task'
desc "Generate documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts = ["-c", "-f nested", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

