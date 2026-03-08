# frozen_string_literal: true

module Mirrorfile
  # Represents a single repository entry to be mirrored.
  #
  # Entry is an immutable data object that holds the URL and local name
  # for a mirrored repository. It provides methods for cloning and updating
  # the repository.
  #
  # @example Creating an entry
  #   entry = Mirrorfile::Entry.new(
  #     url: "https://github.com/rails/rails",
  #     name: "rails-source"
  #   )
  #   entry.install(Pathname.new("mirrors"))
  #
  # @!attribute [r] url
  #   @return [String] the full git URL of the repository
  #
  # @!attribute [r] name
  #   @return [String] the local directory name for the clone
  #
  # @since 0.1.0
  Entry = Data.define(:url, :name) do
    # Returns the local path where this repository will be cloned.
    #
    # @param base_dir [Pathname] the base directory containing all mirrors
    # @return [Pathname] the full path to this repository's local directory
    #
    # @example
    #   entry = Entry.new(url: "https://github.com/rails/rails", name: "rails")
    #   entry.local_path(Pathname.new("/project/mirrors"))
    #   #=> #<Pathname:/project/mirrors/rails>
    def local_path(base_dir)
      base_dir.join(name)
    end

    # Clones the repository if it doesn't already exist locally.
    #
    # This method is idempotent - calling it multiple times will only
    # clone the repository once. If the local directory already exists,
    # no action is taken.
    #
    # After cloning, the .git directory is renamed to the configured
    # git_dir name (default: .git.mirror) so that the host project's
    # git does not treat it as a nested repository.
    #
    # @param base_dir [Pathname] the base directory to clone into
    # @param git_dir [String] the git directory name to use
    #   (default: ".git.mirror", use ".git" for legacy mode)
    # @return [Boolean, nil] true if clone succeeded, false if failed,
    #   nil if already exists
    #
    # @example
    #   entry.install(Pathname.new("mirrors"))
    #
    # @see #update
    def install(base_dir, git_dir: '.git.mirror')
      dir = local_path(base_dir)
      return if dir.exist?

      return unless system('git', 'clone', url, dir.to_s)

      return unless git_dir != '.git'

      File.rename(dir.join('.git').to_s, dir.join(git_dir).to_s)
    end

    # Updates an existing repository by pulling the latest changes.
    #
    # Uses fast-forward only merges to avoid creating merge commits.
    # If the local directory doesn't exist, no action is taken.
    #
    # @param base_dir [Pathname] the base directory containing the clone
    # @param git_dir [String] the git directory name to use
    #   (default: ".git.mirror", use ".git" for legacy mode)
    # @return [Boolean, nil] true if pull succeeded, false if failed,
    #   nil if directory doesn't exist
    #
    # @example
    #   entry.update(Pathname.new("mirrors"))
    #
    # @see #install
    def update(base_dir, git_dir: '.git.mirror')
      dir = local_path(base_dir)
      return unless dir.exist?

      system('git', '--git-dir', dir.join(git_dir).to_s,
             '--work-tree', dir.to_s, 'pull', '--ff-only')
    end

    # Returns a human-readable representation of the entry.
    #
    # @return [String] formatted string showing url and name
    def to_s
      "#{name} (#{url})"
    end
  end
end
