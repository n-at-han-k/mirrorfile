# frozen_string_literal: true

# The version is parsed rather than required so that the gemspec can be
# evaluated on its own — bundlerEnv does exactly that, and copies only this
# file and lib/mirrorfile/version.rb into the store.
version = File.read(File.expand_path("lib/mirrorfile/version.rb", __dir__))[/VERSION = '([^']+)'/, 1]

Gem::Specification.new do |spec|
  spec.name = "mirrorfile"
  spec.version = version
  spec.authors = ["Nathan Kidd"]
  spec.email = ["nathankidd@hey.com"]

  spec.summary = "Manage local mirrors of git repositories"

  spec.description = <<~DESC
    Mirrorfile provides a DSL similar to Bundler's Gemfile for managing local
    mirrors of git repositories. Clone and keep repositories updated with
    simple commands. Includes Rails/Zeitwerk integration for autoloading
    mirrored code.
  DESC

  spec.homepage = "https://github.com/n-at-han-k/mirrorfile"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  # Globbed rather than `git ls-files`: the gemspec is evaluated in the Nix
  # store, where there is no git and the shell-out would abort evaluation.
  spec.files = Dir.glob(
    ["lib/**/*.rb", "exe/*", "templates/*", "CHANGELOG.md", "LICENSE.txt", "README.md"],
    base: __dir__,
  )

  spec.bindir = "exe"
  spec.executables = ["mirror"]
  spec.require_paths = ["lib"]

  spec.add_dependency "gem_kit", "~> 0.2"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "yard", "~> 0.9"
end
