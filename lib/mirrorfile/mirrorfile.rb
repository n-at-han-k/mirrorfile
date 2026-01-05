# frozen_string_literal: true

module Mirrorfile
  # Provides the DSL for parsing and evaluating Mirrorfile contents.
  #
  # Mirrorfile implements a domain-specific language similar to Bundler's
  # Gemfile. It allows users to specify repository sources and mirror
  # definitions in a readable, declarative format.
  #
  # @example Mirrorfile DSL
  #   source "https://github.com"
  #
  #   mirror "rails/rails", as: "rails-source"
  #   mirror "hotwired/turbo-rails"
  #
  #   source "https://gitlab.com"
  #
  #   mirror "org/project"
  #
  # @example Programmatic usage
  #   mirrorfile = Mirrorfile::Mirrorfile.new
  #   mirrorfile.source("https://github.com")
  #   mirrorfile.mirror("rails/rails", as: "rails")
  #   mirrorfile.entries.each { |e| puts e.url }
  #
  # @since 0.1.0
  class Mirrorfile
    # Creates a new Mirrorfile instance.
    #
    # @return [Mirrorfile] a new instance with no entries or source
    def initialize
      @entries = []
      @source = nil
    end

    # Sets the base URL for subsequent mirror declarations.
    #
    # The source URL is prepended to repository paths in following
    # {#mirror} calls until a new source is declared. This allows
    # grouping repositories by host without repeating the full URL.
    #
    # @param url [String] the base URL for repositories (e.g., "https://github.com")
    # @return [String] the normalized source URL (trailing slash removed)
    #
    # @example Setting a GitHub source
    #   source "https://github.com"
    #   mirror "rails/rails"  # clones from https://github.com/rails/rails
    #
    # @example Multiple sources
    #   source "https://github.com"
    #   mirror "user/repo1"
    #
    #   source "https://gitlab.com"
    #   mirror "user/repo2"  # clones from https://gitlab.com/user/repo2
    def source(url)
      @source = url.chomp("/")
    end

    # Declares a repository to be mirrored.
    #
    # If a {#source} has been set, the path is appended to it to form
    # the full URL. Otherwise, the path is treated as a complete URL.
    #
    # @param path [String] the repository path or full URL
    # @param as [String] the local directory name (defaults to repo name)
    # @return [Entry] the newly created entry
    #
    # @example With source set
    #   source "https://github.com"
    #   mirror "rails/rails"                    # uses source + path
    #   mirror "hotwired/turbo", as: "turbo"    # custom local name
    #
    # @example Without source (full URL)
    #   mirror "https://github.com/rails/rails"
    #   mirror "git@github.com:rails/rails.git", as: "rails"
    #
    # @see #source
    def mirror(path, as: File.basename(path, ".git"))
      url = @source ? "#{@source}/#{path}" : path
      Entry.new(url:, name: as).tap { @entries << _1 }
    end

    # Returns a lazy enumerator of all declared entries.
    #
    # Using a lazy enumerator allows for efficient iteration over
    # entries without loading them all into memory at once, and
    # enables chaining with other enumerable methods.
    #
    # @return [Enumerator::Lazy<Entry>] lazy enumerator of Entry objects
    #
    # @example Iterating over entries
    #   mirrorfile.entries.each { |entry| entry.install(base_dir) }
    #
    # @example Filtering entries
    #   mirrorfile.entries
    #     .select { |e| e.name.start_with?("rails") }
    #     .each { |e| e.update(base_dir) }
    def entries
      @entries.lazy
    end

    # Returns the number of declared entries.
    #
    # @return [Integer] the count of mirror entries
    def size
      @entries.size
    end

    # Loads and evaluates a Mirrorfile from disk.
    #
    # @param path [Pathname, String] path to the Mirrorfile
    # @return [Mirrorfile] a new instance with entries from the file
    # @raise [MirrorfileNotFound] if the file doesn't exist
    # @raise [SyntaxError] if the file contains invalid Ruby
    #
    # @example
    #   mirrorfile = Mirrorfile::Mirrorfile.load("Mirrorfile")
    #   mirrorfile.entries.each { |e| puts e.url }
    def self.load(path)
      path = Pathname.new(path)
      raise MirrorfileNotFound, "Mirrorfile not found at #{path}" unless path.exist?

      new.tap { _1.instance_eval(path.read, path.to_s) }
    end
  end
end
