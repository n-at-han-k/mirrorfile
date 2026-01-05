# frozen_string_literal: true

require_relative "lib/mirrorfile/version"

Gem::Specification.new do |spec|
  spec.name = "mirrorfile"
  spec.version = Mirrorfile::VERSION
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

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = ["mirror"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "yard", "~> 0.9"
end
