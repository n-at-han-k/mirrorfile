# frozen_string_literal: true

module Mirrorfile
  # Legacy CLI for projects with old-style .git directories.
  #
  # This CLI is used automatically when mirrorfile detects that the
  # mirrors directory contains repositories with .git instead of
  # .git.mirror. It prints a deprecation warning and operates using
  # the legacy .git directory name.
  #
  # @see CLI
  # @since 1.0.0
  class CLILegacy < CLI
    LEGACY_WARNING = <<~WARN
      [mirrorfile] WARNING: Your mirrors use legacy .git directories.
      Upgrade with mirrorfile v0.1.1 (`mirror migrate-to-v1`), or remove
      the mirrors/ directory and re-run `mirror install`.
    WARN

    # Overrides CLI#call to skip legacy detection and dispatch directly.
    #
    # @param args [Array<String>] command-line arguments
    # @return [Integer] exit status code
    def call(args)
      dispatch(args)
    end

    private

    # Executes the install command in legacy mode.
    #
    # @return [void]
    # @api private
    def install
      @stderr.puts LEGACY_WARNING
      @stdout.puts 'Installing mirrors (legacy mode)...'
      Mirror.new.install(legacy: true)
      @stdout.puts 'Done.'
    end

    # Executes the update command in legacy mode.
    #
    # @return [void]
    # @api private
    def update
      @stderr.puts LEGACY_WARNING
      @stdout.puts 'Updating mirrors (legacy mode)...'
      Mirror.new.update(legacy: true)
      @stdout.puts 'Done.'
    end

    # Executes the list command with a legacy warning.
    #
    # @return [void]
    # @api private
    def list
      @stderr.puts LEGACY_WARNING
      super
    end

    # Executes a git command using the default .git directory.
    #
    # In legacy mode, mirrors have .git (not .git.mirror), so
    # no --git-dir flag is needed.
    #
    # @param args [Array<String>] arguments to pass to git
    # @return [void]
    # @api private
    def git(args)
      @stderr.puts LEGACY_WARNING
      system('git', *args)
    end
  end
end
