#!/usr/bin/env watchr
# vim: filetype=ruby
#
# Thanks to
# http://www.stupididea.com/2009/03/15/non-rails-autotest-rspec-libnotify-linux/
# for inspiration.

def have_notify_send?
  case `which notify-send`.empty?
  when true
    false
  else
    true
  end
end

def error_icon_name 
  "gtk-dialog-error"
end

def success_icon_name
  "gtk-dialog-info"
end

# Rules
watch('^spec/.+_spec\.rb$') { |md| spec md[0] }
watch('^lib/.+\.rb$') { |md| spec "spec/#{File.basename(md[0]).gsub(/\..*?$/, '')}_spec.rb" }
watch('^features/.+\.feature$') { |md| feature md[0] }

# Notify using notify-send.
#
# @param icon [String] name of stock icon to use.
# @param title [String] title of notification.
# @param message [String] message for notification body.
# @return [Boolean] true if the command ran successfully, false
# otherwise.
def notify(icon, title, message)
  system("notify-send -t 3000 -i #{icon} \"#{title}\" \"#{message}\"")
end

# Notify of success.
#
def notify_success
  if have_notify_send?
    notify success_icon_name, "All green!", "Now write more tests :)"
  end
end

# Notify of failure.
#
def notify_failure
  if have_notify_send?
    notify error_icon_name, "Something is broken", "Now go fix it :)"
  end
end

# Run a single ruby command. Notify appropriately.
# 
# @param cmd [String] command to run.
def run(cmd)
  system('clear')
  puts "Running #{cmd}"
  if system(cmd)
    notify_success
  else
    notify_failure
  end
end

# Run a single spec.
#
# @param specfile [String] path to specfile.
def spec(specfile)
  run(%Q(rspec #{rspec_opts} #{specfile}))
end

# Run a single feature.
#
# @param featurefile [String] path to feature file.
def feature(featurefile)
  run(%Q(cucumber #{cucumber_opts} #{featurefile}))
end

# Options for rspec run
#
# @return [String] string with options.
def rspec_opts
  "--format documentation --color"
end

# Options for cucumber run.
#
# @return [String] string with options.
def cucumber_opts
  ""
end

# Run all specs.
#
def run_all_specs
  run "rake spec"
end

# Run all features.
#
def run_features
  run "rake features"
end

# Run specs and features.
#
def run_suite
  run "rake spec features"
end

# Run all specs on Ctrl-\
Signal.trap('QUIT') { run_all_specs }

# Run full suite on one Ctrl-C, quit on two
@interrupted = false
Signal.trap('INT') do
  if @interrupted
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5
    run_suite
    @interrupted = false
  end
end

