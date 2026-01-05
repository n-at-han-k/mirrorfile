# frozen_string_literal: true

module Mirrorfile
  # Command-line interface for Mirrorfile.
  #
  # CLI parses command-line arguments and dispatches to the appropriate
  # {Mirror} methods. It provides a simple, git-like interface for
  # managing mirrored repositories.
  #
  # @example Running from command line
  #   $ mirror init      # Initialize project
  #   $ mirror install   # Clone repositories
  #   $ mirror update    # Pull latest changes
  #   $ mirror list      # Show all mirrors
  #
  # @example Programmatic usage
  #   cli = Mirrorfile::CLI.new
  #   cli.call(["install"])
  #
  # @since 0.1.0
  class CLI
    # Available CLI commands
    # @return [Array<String>] list of valid commands
    COMMANDS = %w[init install update list help].freeze

    # Creates a new CLI instance.
    #
    # @param stdout [IO] output stream for normal messages (default: $stdout)
    # @param stderr [IO] output stream for error messages (default: $stderr)
    # @return [CLI] a new CLI instance
    def initialize(stdout: $stdout, stderr: $stderr)
      @stdout = stdout
      @stderr = stderr
    end

    # Parses arguments and executes the appropriate command.
    #
    # @param args [Array<String>] command-line arguments (typically ARGV)
    # @return [Integer] exit status code (0 for success, 1 for error)
    #
    # @example
    #   cli = Mirrorfile::CLI.new
    #   exit_code = cli.call(["install"])
    #
    # @example With error handling
    #   cli = Mirrorfile::CLI.new
    #   exit cli.call(ARGV)
    def call(args)
      command = args.first

      case command
      when "init"    then init
      when "install" then install
      when "update"  then update
      when "list"    then list
      when "help"    then help
      when "-h", "--help" then help
      when "-v", "--version" then version
      else                usage
      end

      0
    rescue MirrorfileNotFound => e
      @stderr.puts "Error: #{e.message}"
      1
    rescue StandardError => e
      @stderr.puts "Error: #{e.message}"
      @stderr.puts e.backtrace.first(5).map { "  #{_1}" } if ENV["DEBUG"]
      1
    end

    private

    # Executes the init command.
    #
    # @return [void]
    # @api private
    def init
      Mirror.new.init
    end

    # Executes the install command.
    #
    # @return [void]
    # @api private
    def install
      @stdout.puts "Installing mirrors..."
      Mirror.new.install
      @stdout.puts "Done."
    end

    # Executes the update command.
    #
    # @return [void]
    # @api private
    def update
      @stdout.puts "Updating mirrors..."
      Mirror.new.update
      @stdout.puts "Done."
    end

    # Executes the list command.
    #
    # @return [void]
    # @api private
    def list
      entries = Mirror.new.list

      entries.empty? ? @stdout.puts("No mirrors defined.") : entries.each { @stdout.puts _1 }
    end

    # Displays help information.
    #
    # @return [void]
    # @api private
    def help
      @stdout.puts <<~HELP
        Mirrorfile - Manage local mirrors of git repositories

        Usage: mirror <command>

        Commands:
          init      Initialize project with Mirrorfile, .gitignore entry,
                    and Zeitwerk initializer for Rails projects
          install   Clone repositories that don't exist locally
          update    Pull latest changes for existing repositories
          list      Show all defined mirrors
          help      Show this help message

        Options:
          -h, --help     Show this help message
          -v, --version  Show version number

        Examples:
          $ mirror init
          $ mirror install
          $ mirror update

        Mirrorfile syntax:
          source "https://github.com"

          mirror "rails/rails", as: "rails-source"
          mirror "hotwired/turbo-rails"

          source "https://gitlab.com"

          mirror "org/project"

        For more information, see: https://github.com/n-at-han-k/mirrorfile
      HELP
    end

    # Displays version information.
    #
    # @return [void]
    # @api private
    def version
      @stdout.puts "mirrorfile #{Mirrorfile::VERSION}"
    end

    # Displays usage information for unknown commands.
    #
    # @return [void]
    # @api private
    def usage
      @stderr.puts <<~USAGE
        Usage: mirror <command>

        Commands:
          init      Create Mirrorfile, .gitignore entry, and Zeitwerk initializer
          install   Clone repositories that don't exist locally
          update    Pull latest changes for existing repositories
          list      Show all defined mirrors
          help      Show detailed help

        Run 'mirror help' for more information.
      USAGE
    end
  end
end
