source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in refine-rails.gemspec.
gemspec

gem "mysql2"

gem "sprockets-rails"
gem "byebug"

group :development, :test do
  gem "minitest-around"
  gem "minitest-ci"
  gem "net-http" # added to fix warnings - https://github.com/rails/rails/pull/44175#issuecomment-1023595691
  gem "standard"
end

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
