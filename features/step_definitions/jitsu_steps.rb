require 'tmpdir'

Given /^a directory$/ do
  @tmpdir = Dir.mktmpdir
  puts "Tempdir for this scenario: #{@tmpdir}"
end

Given /^a file "([^"]*)" with contents$/ do |filename, contents|
  Dir.chdir @tmpdir do |dir|
    File.open filename, 'w' do |f|
      f.write contents
    end
  end
end

When /^I run jitsu$/ do
  Dir.chdir @tmpdir do |dir|
    Jitsu.work
  end
end

When /^I run "([^"]*)"$/ do |command|
  parts = command.split(/ /)
  Dir.chdir @tmpdir do |dir|
    parts[0] = File.expand_path(parts[0]) if parts[0].index(/\//)
    @output = `#{parts.join(' ')}`
    $?.should == 0
  end
end

Then /^the output should be "([^"]*)" with a newline$/ do |desired|
  @output.should == desired + "\n"
end

Then /^running jitsu should produce an error$/ do
    pending # express the regexp above with the code you wish you had
end

