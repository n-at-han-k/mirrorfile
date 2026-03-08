# frozen_string_literal: true

require 'fileutils'

module Mirrorfile
  # Orchestrates mirror operations: init, install, and update.
  #
  # Mirror is the main interface for performing operations on mirrored
  # repositories. It handles loading the Mirrorfile, creating necessary
  # directories and files, and delegating to individual entries.
  #
  # @example Initializing a new project
  #   mirror = Mirrorfile::Mirror.new
  #   mirror.init
  #
  # @example Installing and updating mirrors
  #   mirror = Mirrorfile::Mirror.new
  #   mirror.install  # Clone missing repositories
  #   mirror.update   # Pull latest changes
  #
  # @since 0.1.0
  class Mirror
    # @return [Pathname] the project root directory
    attr_reader :root

    # @return [Pathname] the mirrors directory path
    attr_reader :mirrors_dir

    # @return [Pathname] the .gitignore file path
    attr_reader :gitignore_path

    # @return [Pathname] the Mirrorfile path
    attr_reader :mirrorfile_path

    # @return [Pathname] the Rails initializer path
    attr_reader :initializer_path

    # Creates a new Mirror instance.
    #
    # @param root [Pathname, String] the project root directory
    #   (defaults to current working directory)
    # @return [Mirror] a new Mirror instance
    #
    # @example With default root
    #   mirror = Mirrorfile::Mirror.new
    #
    # @example With custom root
    #   mirror = Mirrorfile::Mirror.new(root: "/path/to/project")
    def initialize(root: Dir.pwd)
      @root = Pathname.new(root)
      @mirrors_dir = @root.join('mirrors')
      @gitignore_path = @root.join('.gitignore')
      @mirrorfile_path = @root.join('Mirrorfile')
      @initializer_path = @root.join('config/initializers/mirrors.rb')
      @mirrorfile = load_mirrorfile if @mirrorfile_path.exist?
    end

    # Clones all repositories that don't exist locally.
    #
    # Creates the mirrors directory if it doesn't exist, then iterates
    # through all entries in the Mirrorfile and clones any that are missing.
    #
    # @return [void]
    # @raise [MirrorfileNotFound] if Mirrorfile doesn't exist
    #
    # @example
    #   mirror = Mirrorfile::Mirror.new
    #   mirror.install
    #
    # @see Entry#install
    def install
      ensure_mirrorfile!
      mirrors_dir.mkpath
      @mirrorfile.entries.each { _1.install(mirrors_dir) }
    end

    # Updates all existing local repositories.
    #
    # Iterates through all entries in the Mirrorfile and pulls the latest
    # changes for any that exist locally. Repositories that haven't been
    # cloned are skipped.
    #
    # @return [void]
    # @raise [MirrorfileNotFound] if Mirrorfile doesn't exist
    #
    # @example
    #   mirror = Mirrorfile::Mirror.new
    #   mirror.update
    #
    # @see Entry#update
    def update
      ensure_mirrorfile!
      @mirrorfile.entries.each { _1.update(mirrors_dir) }
    end

    # Initializes a new project with mirror support.
    #
    # This method creates all necessary files and directories for using
    # Mirrorfile in a project:
    #
    # - Creates a Mirrorfile with example syntax
    # - Adds /mirrors to .gitignore (creates file if needed)
    # - Creates a Rails initializer for Zeitwerk autoloading (Rails projects only)
    #
    # Existing files are not overwritten.
    #
    # @return [void]
    #
    # @example
    #   mirror = Mirrorfile::Mirror.new
    #   mirror.init
    #   # => Creates Mirrorfile, updates .gitignore, creates initializer
    #
    # @see #create_mirrorfile
    # @see #setup_gitignore
    # @see #setup_zeitwerk
    def init
      create_mirrorfile
      setup_gitignore
      setup_templates
      setup_zeitwerk
      puts "Initialized mirrors in #{root}"
    end

    # Lists all entries in the Mirrorfile.
    #
    # @return [Array<Entry>] array of all mirror entries
    # @raise [MirrorfileNotFound] if Mirrorfile doesn't exist
    #
    # @example
    #   mirror.list.each { |entry| puts entry }
    def list
      ensure_mirrorfile!
      @mirrorfile.entries.to_a
    end

    private

    # Loads and parses the Mirrorfile.
    #
    # @return [Mirrorfile] the parsed Mirrorfile
    # @api private
    def load_mirrorfile
      Mirrorfile.load(mirrorfile_path)
    end

    # Raises an error if Mirrorfile doesn't exist.
    #
    # @raise [MirrorfileNotFound] if Mirrorfile doesn't exist
    # @return [void]
    # @api private
    def ensure_mirrorfile!
      raise MirrorfileNotFound, "Run 'mirror init' first" unless @mirrorfile
    end

    # Creates a new Mirrorfile with example syntax.
    #
    # Does nothing if Mirrorfile already exists.
    #
    # @return [Integer, nil] bytes written or nil if file exists
    # @api private
    def create_mirrorfile
      mirrorfile_path.exist? || mirrorfile_path.write(<<~RUBY)
        # frozen_string_literal: true

        # Mirror repositories
        #
        # Set a source for subsequent mirror declarations:
        #
        #   source "https://github.com"
        #
        # Then declare mirrors with optional custom names:
        #
        #   mirror "user/repo"
        #   mirror "user/other-repo", as: "custom-name"
        #
        # You can change sources mid-file:
        #
        #   source "https://gitlab.com"
        #
        #   mirror "org/project"
        #
        # Or use full URLs without a source:
        #
        #   mirror "https://bitbucket.org/team/repo"

        source "https://github.com"

        # mirror "rails/rails", as: "rails-source"
      RUBY
    end

    # Adds /mirrors to .gitignore.
    #
    # Creates .gitignore if it doesn't exist. Appends the ignore
    # pattern only if not already present.
    #
    # @return [Integer, nil] bytes written or nil if already ignored
    # @api private
    def setup_gitignore
      gitignore_path.exist? || gitignore_path.write('')

      lines = gitignore_path.readlines.map(&:chomp)
      lines.include?('/mirrors') || gitignore_path.write([*lines, '/mirrors'].join("\n") + "\n")
    end

    # Creates a Rails initializer for Zeitwerk autoloading.
    #
    # The initializer configures Zeitwerk to autoload code from
    # lib/ directories within mirrored repositories.
    #
    # Does nothing if initializer already exists.
    #
    # @return [Integer, nil] bytes written or nil if file exists
    # @api private
    def setup_zeitwerk
      return unless rails_project?

      initializer_path.dirname.mkpath
      initializer_path.exist? || initializer_path.write(<<~RUBY)
        # frozen_string_literal: true

        # Autoload mirrored repositories
        #
        # This initializer configures Zeitwerk to autoload code from
        # lib/ directories within mirrored repositories.
        #
        # @see https://github.com/fxn/zeitwerk

        Rails.autoloaders.main.tap do |loader|
          mirrors = Rails.root.join("mirrors")

          mirrors.glob("*/lib").each do |lib_path|
            loader.push_dir(lib_path)
          end if mirrors.exist?
        end
      RUBY
    end

    # Copies template files into the mirrors directory.
    #
    # Creates the mirrors directory if it doesn't exist, then copies
    # envrc.template and README.md.template from the gem's
    # templates directory. Existing files are not overwritten.
    #
    # @return [void]
    # @api private
    def setup_templates
      mirrors_dir.mkpath

      templates_dir = Pathname.new(__dir__).join('../../templates')

      envrc_dest = mirrors_dir.join('.envrc')
      envrc_dest.exist? || FileUtils.cp(templates_dir.join('envrc.template'), envrc_dest)

      readme_dest = mirrors_dir.join('README.md')
      readme_dest.exist? || FileUtils.cp(templates_dir.join('README.md.template'), readme_dest)
    end

    # Determines if the current project is a Rails application by checking
    # for the standard Rails application entrypoint.
    #
    # @return [Boolean] true if Rails project structure is detected
    # @api private
    def rails_project?
      root.join('config/application.rb').exist?
    end
  end
end
