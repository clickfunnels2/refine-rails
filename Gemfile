source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Considering we are using a specific version of Rails for testing
# and that the gemspec's only dependency is `"rails", ">= 6.1.1"`,
# we exclude the call to `gemspec` and instead specify the Rails
# version that will be used when developing locally.
#
# This *should* have no impact on the Rails version that is used when
# added to an app.
#
# gemspec
#
gem "rails", "6.1.1"

gem "mysql2"

gem "sprockets-rails"
gem "byebug"

group :development, :test do
  gem "minitest-around"
  gem "minitest-ci"
  gem "standard"
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
