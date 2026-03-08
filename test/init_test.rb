# frozen_string_literal: true

require 'test_helper'

class InitTest < Minitest::Test
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
