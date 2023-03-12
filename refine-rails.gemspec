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
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib,public}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0"
end
