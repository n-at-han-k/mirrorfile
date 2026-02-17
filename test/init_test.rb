# frozen_string_literal: true

require "test_helper"

class InitTest < Minitest::Test
  def test_init_skips_initializer_outside_rails
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Mirrorfile::Mirror.new.init

        refute File.exist?(File.join(dir, "config", "initializers", "mirrors.rb"))
        assert File.exist?(File.join(dir, "Mirrorfile"))
        assert File.exist?(File.join(dir, ".gitignore"))
        refute Dir.exist?(File.join(dir, "config"))
      end
    end
  end

  def test_init_creates_initializer_for_rails_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        FileUtils.mkdir_p(File.join("config"))
        File.write(File.join("config", "application.rb"), "# Rails app\n")

        Mirrorfile::Mirror.new.init

        assert File.exist?(File.join(dir, "config", "initializers", "mirrors.rb"))
      end
    end
  end
end
