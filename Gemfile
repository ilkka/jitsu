source "http://rubygems.org"
gem "trollop", "~> 2.0"
gem "kwalify", "~> 0.7"

group :development do
  gem "yard", "~> 0.8"
  gem "jeweler", "~> 1.8"
end

group :test do
  gem "rspec", "~> 2.14"
  gem "cucumber", "~> 1.3"
  if not RUBY_ENGINE and RUBY_VERSION =~ /^1.8/
    gem "rcov", "~> 1.0"
  end
end
