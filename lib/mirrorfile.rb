# frozen_string_literal: true

require "pathname"

require_relative "mirrorfile/version"
require_relative "mirrorfile/entry"
require_relative "mirrorfile/mirrorfile"
require_relative "mirrorfile/mirror"
require_relative "mirrorfile/cli"

# Mirrorfile is a gem for managing local mirrors of git repositories.
#
# It provides a DSL similar to Bundler's Gemfile for specifying repositories
# to clone and keep updated locally. This is useful for vendoring dependencies,
# referencing source code, or maintaining offline copies of repositories.
#
# @example Basic usage with a Mirrorfile
#   # Mirrorfile
#   source "https://github.com"
#
#   mirror "rails/rails", as: "rails-source"
#   mirror "hotwired/turbo-rails"
#
# @example Command line usage
#   $ bin/mirror init     # Initialize project with Mirrorfile
#   $ bin/mirror install  # Clone all repositories
#   $ bin/mirror update   # Pull latest changes
#
# @author Your Name
# @since 0.1.0
module Mirrorfile
  class Error < StandardError; end

  # Error raised when Mirrorfile is not found
  class MirrorfileNotFound < Error; end

  # Error raised when a git operation fails
  class GitOperationError < Error; end

  class << self
    # Returns the root path for mirror operations
    #
    # @return [Pathname] the current working directory as a Pathname
    def root
      Pathname.new(Dir.pwd)
    end

    # Returns the path to the mirrors directory
    #
    # @return [Pathname] path to the mirrors directory
    def mirrors_dir
      root.join("mirrors")
    end

    # Returns the path to the Mirrorfile
    #
    # @return [Pathname] path to the Mirrorfile
    def mirrorfile_path
      root.join("Mirrorfile")
    end
  end
end
