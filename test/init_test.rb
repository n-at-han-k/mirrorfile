# frozen_string_literal: true

require 'test_helper'
require 'minitest/mock'

class InitTest < Minitest::Test
  def test_init_adds_dependency_in_project_root
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), "source 'https://rubygems.org'\n")
      mirror = Mirrorfile::Mirror.new(root: dir)
      calls = []

      run_bundle = lambda do |*args, **options|
        refute ENV.key?('BUNDLE_GEMFILE')
        calls << [args, options]
        File.open(File.join(dir, 'Gemfile'), 'a') { |file| file.puts "gem 'mirrorfile'" }
        true
      end

      mirror.stub(:system, run_bundle) do
        mirror.init
        mirror.init
      end

      assert_equal [[['bundle', 'add', 'mirrorfile'], { chdir: dir }]], calls
    end
  end

  def test_init_does_not_treat_a_commented_dependency_as_installed
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), "source 'https://rubygems.org'\n# gem 'mirrorfile'\n")
      mirror = Mirrorfile::Mirror.new(root: dir)
      called = false

      mirror.stub(:system, ->(*) { called = true }) do
        mirror.init
      end

      assert called
    end
  end

  def test_init_skips_dependency_without_gemfile
    Dir.mktmpdir do |dir|
      mirror = Mirrorfile::Mirror.new(root: dir)
      mirror.stub(:system, ->(*) { flunk 'Bundler should not run without a Gemfile' }) do
        mirror.init
      end

      refute File.exist?(File.join(dir, 'Gemfile'))
    end
  end

  def test_init_preserves_existing_dependency
    Dir.mktmpdir do |dir|
      gemfile = File.join(dir, 'Gemfile')
      original = "source 'https://rubygems.org'\ngem 'mirrorfile', '~> 1.0'\n"
      File.write(gemfile, original)
      mirror = Mirrorfile::Mirror.new(root: dir)

      mirror.stub(:system, ->(*) { flunk 'Bundler should not run for an existing dependency' }) do
        mirror.init
      end

      assert_equal original, File.read(gemfile)
    end
  end

  def test_init_reports_dependency_installation_failure
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'Gemfile'), "source 'https://rubygems.org'\n")
      mirror = Mirrorfile::Mirror.new(root: dir)

      mirror.stub(:system, false) do
        error = assert_raises(Mirrorfile::Error) { mirror.init }
        assert_includes error.message, 'bundle add mirrorfile'
      end
    end
  end

  def test_init_skips_initializer_outside_rails
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.init

        refute File.exist?(File.join(dir, 'config', 'initializers', 'mirrors.rb'))
        assert File.exist?(File.join(dir, 'Mirrorfile'))
        assert File.exist?(File.join(dir, '.gitignore'))
        refute Dir.exist?(File.join(dir, 'config'))
      end
    end
  end

  def test_init_creates_initializer_for_rails_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(File.join('config'))
        File.write(File.join('config', 'application.rb'), "# Rails app\n")

        Mirrorfile::Mirror.new.init

        assert File.exist?(File.join(dir, 'config', 'initializers', 'mirrors.rb'))
      end
    end
  end

  def test_init_copies_envrc_template
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.init

        envrc_path = File.join(dir, 'mirrors', '.envrc')
        assert File.exist?(envrc_path)

        template_path = File.expand_path('../templates/envrc.template', __dir__)
        assert_equal File.read(template_path), File.read(envrc_path)
      end
    end
  end

  def test_init_copies_readme_template
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.init

        readme_path = File.join(dir, 'mirrors', 'README.md')
        assert File.exist?(readme_path)

        template_path = File.expand_path('../templates/README.md.template', __dir__)
        assert_equal File.read(template_path), File.read(readme_path)
      end
    end
  end

  def test_init_does_not_overwrite_existing_templates
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p('mirrors')
        File.write(File.join('mirrors', '.envrc'), "custom content\n")
        File.write(File.join('mirrors', 'README.md'), "custom instructions\n")

        Mirrorfile::Mirror.new.init

        assert_equal "custom content\n", File.read(File.join(dir, 'mirrors', '.envrc'))
        assert_equal "custom instructions\n", File.read(File.join(dir, 'mirrors', 'README.md'))
      end
    end
  end
end
