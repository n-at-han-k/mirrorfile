# frozen_string_literal: true

require 'test_helper'

class MigrateTest < Minitest::Test
  def test_migrate_updates_gemfile_version
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('Gemfile', <<~GEMFILE)
          source "https://rubygems.org"

          gem "mirrorfile", "~> 0.1"
        GEMFILE

        Mirrorfile::Mirror.new.migrate_to_v1

        assert_includes File.read('Gemfile'), 'gem "mirrorfile", "~> 1.0"'
      end
    end
  end

  def test_migrate_updates_gemfile_without_version
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('Gemfile', <<~GEMFILE)
          source "https://rubygems.org"

          gem "mirrorfile"
        GEMFILE

        Mirrorfile::Mirror.new.migrate_to_v1

        assert_includes File.read('Gemfile'), 'gem "mirrorfile", "~> 1.0"'
      end
    end
  end

  def test_migrate_leaves_gemfile_alone_if_missing
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.migrate_to_v1

        refute File.exist?('Gemfile')
      end
    end
  end

  def test_migrate_leaves_gemfile_alone_if_no_mirrorfile_gem
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('Gemfile', <<~GEMFILE)
          source "https://rubygems.org"

          gem "rails"
        GEMFILE

        original = File.read('Gemfile')
        Mirrorfile::Mirror.new.migrate_to_v1

        assert_equal original, File.read('Gemfile')
      end
    end
  end

  def test_migrate_installs_envrc_template
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.migrate_to_v1

        envrc_path = File.join(dir, 'mirrors', '.envrc')
        assert File.exist?(envrc_path)

        template_path = File.expand_path('../templates/envrc.template', __dir__)
        assert_equal File.read(template_path), File.read(envrc_path)
      end
    end
  end

  def test_migrate_installs_readme_template
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.migrate_to_v1

        readme_path = File.join(dir, 'mirrors', 'README.md')
        assert File.exist?(readme_path)

        template_path = File.expand_path('../templates/README.md.template', __dir__)
        assert_equal File.read(template_path), File.read(readme_path)
      end
    end
  end

  def test_migrate_does_not_overwrite_existing_templates
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('mirrors')
        File.write(File.join('mirrors', '.envrc'), "custom\n")
        File.write(File.join('mirrors', 'README.md'), "custom\n")

        Mirrorfile::Mirror.new.migrate_to_v1

        assert_equal "custom\n", File.read(File.join('mirrors', '.envrc'))
        assert_equal "custom\n", File.read(File.join('mirrors', 'README.md'))
      end
    end
  end

  def test_migrate_renames_git_dirs
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('mirrors/some-repo/.git')

        Mirrorfile::Mirror.new.migrate_to_v1

        refute Dir.exist?(File.join('mirrors', 'some-repo', '.git'))
        assert Dir.exist?(File.join('mirrors', 'some-repo', '.git.mirror'))
      end
    end
  end

  def test_migrate_skips_already_renamed_git_dirs
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('mirrors/some-repo/.git.mirror')

        Mirrorfile::Mirror.new.migrate_to_v1

        assert Dir.exist?(File.join('mirrors', 'some-repo', '.git.mirror'))
      end
    end
  end

  def test_migrate_does_not_rename_if_both_exist
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('mirrors/some-repo/.git')
        FileUtils.mkdir_p('mirrors/some-repo/.git.mirror')

        Mirrorfile::Mirror.new.migrate_to_v1

        # Both should still exist — don't clobber .git.mirror
        assert Dir.exist?(File.join('mirrors', 'some-repo', '.git'))
        assert Dir.exist?(File.join('mirrors', 'some-repo', '.git.mirror'))
      end
    end
  end

  def test_migrate_is_idempotent
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write('Gemfile', <<~GEMFILE)
          source "https://rubygems.org"

          gem "mirrorfile", "~> 0.1"
        GEMFILE
        FileUtils.mkdir_p('mirrors/some-repo/.git')

        mirror = Mirrorfile::Mirror.new
        mirror.migrate_to_v1
        mirror.migrate_to_v1

        assert_includes File.read('Gemfile'), 'gem "mirrorfile", "~> 1.0"'
        assert File.exist?(File.join('mirrors', '.envrc'))
        assert File.exist?(File.join('mirrors', 'README.md'))
        assert Dir.exist?(File.join('mirrors', 'some-repo', '.git.mirror'))
      end
    end
  end

  def test_deprecation_warning_shown_on_regular_commands
    stdout = StringIO.new
    stderr = StringIO.new
    cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        cli.call(['help'])
      end
    end

    assert_includes stderr.string, 'WARNING'
    assert_includes stderr.string, 'migrate-to-v1'
  end

  def test_no_deprecation_warning_on_migrate
    stdout = StringIO.new
    stderr = StringIO.new
    cli = Mirrorfile::CLI.new(stdout: stdout, stderr: stderr)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        cli.call(['migrate-to-v1'])
      end
    end

    refute_includes stderr.string, 'WARNING'
  end
end
