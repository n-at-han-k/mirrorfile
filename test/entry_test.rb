# frozen_string_literal: true

require "test_helper"

class EntryTest < Minitest::Test
  def test_local_path
    entry = Mirrorfile::Entry.new(url: "https://github.com/rails/rails", name: "rails")
    base = Pathname.new("/project/mirrors")

    assert_equal Pathname.new("/project/mirrors/rails"), entry.local_path(base)
  end

  def test_to_s
    entry = Mirrorfile::Entry.new(url: "https://github.com/rails/rails", name: "rails-source")

    assert_equal "rails-source (https://github.com/rails/rails)", entry.to_s
  end

  def test_immutability
    entry = Mirrorfile::Entry.new(url: "https://github.com/rails/rails", name: "rails")

    assert_raises(FrozenError) { entry.instance_variable_set(:@url, "other") }
  end
end
