# frozen_string_literal: true

require "test_helper"

class MirrorfileTest < Minitest::Test
  def test_mirror_without_source
    mirrorfile = Mirrorfile::Mirrorfile.new
    mirrorfile.mirror("https://github.com/rails/rails")

    entry = mirrorfile.entries.first
    assert_equal "https://github.com/rails/rails", entry.url
    assert_equal "rails", entry.name
  end

  def test_mirror_with_custom_name
    mirrorfile = Mirrorfile::Mirrorfile.new
    mirrorfile.mirror("https://github.com/rails/rails", as: "rails-source")

    entry = mirrorfile.entries.first
    assert_equal "rails-source", entry.name
  end

  def test_source_prepends_to_path
    mirrorfile = Mirrorfile::Mirrorfile.new
    mirrorfile.source("https://github.com")
    mirrorfile.mirror("rails/rails")

    entry = mirrorfile.entries.first
    assert_equal "https://github.com/rails/rails", entry.url
  end

  def test_source_strips_trailing_slash
    mirrorfile = Mirrorfile::Mirrorfile.new
    mirrorfile.source("https://github.com/")
    mirrorfile.mirror("rails/rails")

    entry = mirrorfile.entries.first
    assert_equal "https://github.com/rails/rails", entry.url
  end

  def test_multiple_sources
    mirrorfile = Mirrorfile::Mirrorfile.new

    mirrorfile.source("https://github.com")
    mirrorfile.mirror("rails/rails")

    mirrorfile.source("https://gitlab.com")
    mirrorfile.mirror("org/project")

    entries = mirrorfile.entries.to_a
    assert_equal "https://github.com/rails/rails", entries[0].url
    assert_equal "https://gitlab.com/org/project", entries[1].url
  end

  def test_entries_returns_lazy_enumerator
    mirrorfile = Mirrorfile::Mirrorfile.new
    assert_kind_of Enumerator::Lazy, mirrorfile.entries
  end

  def test_size
    mirrorfile = Mirrorfile::Mirrorfile.new
    mirrorfile.mirror("https://github.com/a/b")
    mirrorfile.mirror("https://github.com/c/d")

    assert_equal 2, mirrorfile.size
  end

  def test_load_from_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "Mirrorfile")
      File.write(path, <<~RUBY)
        source "https://github.com"
        mirror "rails/rails", as: "rails"
      RUBY

      mirrorfile = Mirrorfile::Mirrorfile.load(path)
      entry = mirrorfile.entries.first

      assert_equal "https://github.com/rails/rails", entry.url
      assert_equal "rails", entry.name
    end
  end

  def test_load_raises_for_missing_file
    assert_raises(Mirrorfile::MirrorfileNotFound) do
      Mirrorfile::Mirrorfile.load("/nonexistent/Mirrorfile")
    end
  end
end
