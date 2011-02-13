require 'tmpdir'

Given /^a directory$/ do
  @tmpdir = Dir.mktmpdir
end

Given /^a file "([^"]*)" with contents$/ do |filename, contents|
  Dir.chdir @tmpdir do |dir|
    File.open filename, 'w' do |f|
      f.write contents
    end
  end
end

When /^I run jitsu$/ do
    pending # express the regexp above with the code you wish you had
end

When /^I run "([^"]*)"$/ do |arg1|
    pending # express the regexp above with the code you wish you had
end

Then /^the output should be "([^"]*)"$/ do |arg1|
    pending # express the regexp above with the code you wish you had
end

