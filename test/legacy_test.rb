# frozen_string_literal: true

require 'test_helper'
require 'stringio'

class LegacyTest < Minitest::Test
  # --- Mirror#legacy? detection ---

  def test_legacy_with_git_dir
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'some-repo', '.git'))

      mirror = Mirrorfile::Mirror.new(root: dir)

      assert mirror.legacy?
    end
  end

  def test_not_legacy_with_git_mirror_dir
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'some-repo', '.git.mirror'))

      mirror = Mirrorfile::Mirror.new(root: dir)

      refute mirror.legacy?
    end
  end

  def test_not_legacy_with_no_mirrors_dir
    Dir.mktmpdir do |dir|
      mirror = Mirrorfile::Mirror.new(root: dir)

      refute mirror.legacy?
    end
  end

  def test_not_legacy_with_empty_mirrors_dir
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'mirrors'))

      mirror = Mirrorfile::Mirror.new(root: dir)

      refute mirror.legacy?
    end
  end

  def test_legacy_with_mixed_dirs
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'old-repo', '.git'))
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'new-repo', '.git.mirror'))

      mirror = Mirrorfile::Mirror.new(root: dir)

      assert mirror.legacy?
    end
  end

  def test_not_legacy_when_both_git_and_git_mirror_exist
    Dir.mktmpdir do |dir|
      # If .git.mirror exists alongside .git, it's been migrated
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'repo', '.git'))
      FileUtils.mkdir_p(File.join(dir, 'mirrors', 'repo', '.git.mirror'))

      mirror = Mirrorfile::Mirror.new(root: dir)

      refute mirror.legacy?
    end
  end

  # --- CLI legacy delegation ---

  def test_legacy_cli_prints_warning_on_list
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Set up a legacy mirror and a Mirrorfile
        FileUtils.mkdir_p(File.join('mirrors', 'some-repo', '.git'))
        File.write('Mirrorfile', <<~RUBY)
          source "https://github.com"
        RUBY

        stdout = StringIO.new
        stderr = StringIO.new
        cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)
        cli.call(['list'])

        assert_includes stderr.string, 'WARNING'
        assert_includes stderr.string, 'legacy .git'
      end
    end
  end

  def test_new_style_cli_no_warning_on_list
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(File.join('mirrors', 'some-repo', '.git.mirror'))
        File.write('Mirrorfile', <<~RUBY)
          source "https://github.com"
        RUBY

        stdout = StringIO.new
        stderr = StringIO.new
        cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)
        cli.call(['list'])

        refute_includes stderr.string, 'WARNING'
      end
    end
  end

  def test_init_always_uses_new_cli
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Even with legacy mirrors, init should not print legacy warning
        FileUtils.mkdir_p(File.join('mirrors', 'some-repo', '.git'))

        stdout = StringIO.new
        stderr = StringIO.new
        cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)
        cli.call(['init'])

        refute_includes stderr.string, 'WARNING'
      end
    end
  end

  def test_help_always_uses_new_cli
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(File.join('mirrors', 'some-repo', '.git'))

        stdout = StringIO.new
        stderr = StringIO.new
        cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)
        cli.call(['help'])

        refute_includes stderr.string, 'WARNING'
        assert_includes stdout.string, 'Mirrorfile'
      end
    end
  end

  def test_version_always_uses_new_cli
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(File.join('mirrors', 'some-repo', '.git'))

        stdout = StringIO.new
        stderr = StringIO.new
        cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)
        cli.call(['--version'])

        refute_includes stderr.string, 'WARNING'
        assert_includes stdout.string, Mirrorfile::VERSION
      end
    end
  end

  # --- Entry git_dir parameter ---

  def test_entry_update_uses_custom_git_dir
    Dir.mktmpdir do |dir|
      # Create a fake mirror with .git (legacy)
      repo_dir = File.join(dir, 'mirrors', 'fake-repo')
      FileUtils.mkdir_p(File.join(repo_dir, '.git'))

      entry = Mirrorfile::Entry.new(url: 'https://example.com/repo', name: 'fake-repo')

      # update with git_dir: ".git" should attempt git pull using .git
      # It will fail (not a real repo) but should not error looking for .git.mirror
      result = entry.update(Pathname.new(File.join(dir, 'mirrors')), git_dir: '.git')

      # false means the git command ran but failed (not a real repo)
      assert_equal false, result
    end
  end
end
