require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "jitsu"
  gem.homepage = "http://github.com/ilkka/jitsu"
  gem.license = "MIT"
  gem.summary = %Q{Meta build system for Ninja}
  gem.description = <<-EOS
Jitsu is a frontend or meta build system for Ninja
(http://github.com/martine/ninja), a lightning-fast but
in itself (and by design) feature-poor build system.
Jitsu reads project descriptions and generates Ninja
buildfiles.
EOS
  gem.email = "ilkka.s.laukkanen@gmail.com"
  gem.authors = ["Ilkka Laukkanen"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'cucumber/rake/task'
Cucumber::Rake::Task.new(:features)

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
