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
watch('^spec/.*_spec\.rb$') { |md| spec md[0] }
watch('^lib/(.*)\.rb$') { |md| spec "spec/#{md[1]}_spec.rb" }

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
    notify success_icon_name, "All specs green!", "Now write more specs!"
  end
end

# Notify of failure.
#
def notify_failure
  if have_notify_send?
    notify error_icon_name, "Some specs red :(", "Now go fix 'em"
  end
end

# Run a single ruby command. Notify appropriately.
# 
# @param cmd [String] command to run.
# @return [String] output from the command
def run(cmd)
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
# @return nil.
def spec(specfile)
  system('clear')
  result = run(%Q(rspec #{rspec_opts} #{specfile}))
end

def rspec_opts
  "--format documentation --color"
end
