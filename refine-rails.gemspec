require_relative "lib/refine/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "refine-rails"
  spec.version     = Refine::Rails::VERSION
  spec.authors     = ["Colleen Schnettler", "Aaron Francis"]
  spec.email       = %w[colleen@hammerstone.dev aaron@hammerstone.dev eric@berry.sh]
  spec.homepage    = "https://hammerstone.dev"
  spec.summary     = "Visual query builder for Rails"
  spec.description = "Refine is a flexible query builder for your apps. It lets your users filter down to exactly what they're looking for. Completely configured on the backend."
  spec.license     = "Nonstandard"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://do-not-deploy-with-gem-push"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hammerstonedev/refine-rails"
  # spec.metadata["changelog_uri"] = "https://github.com/hammerstonedev/refine-rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "Rakefile", "README.md"]
  end

  spec.required_ruby_version = ">= 2.7"
  spec.add_dependency "rails", ">= 6.1"
  spec.add_dependency "turbo-rails", ">= 1.1"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "faker"
  spec.add_development_dependency "importmap-rails"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sprockets-rails"
  spec.add_development_dependency "tailwindcss-rails"
  spec.add_development_dependency "web-console"
  spec.add_development_dependency "webdrivers"
end
