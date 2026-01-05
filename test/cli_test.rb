# frozen_string_literal: true

require "test_helper"
require "stringio"

class CLITest < Minitest::Test
  def setup
    @stdout = StringIO.new
    @stderr = StringIO.new
    @cli = Mirrorfile::CLI.new(stdout: @stdout, stderr: @stderr)
  end

  def test_help_command
    @cli.call(["help"])

    assert_includes @stdout.string, "Mirrorfile"
    assert_includes @stdout.string, "Commands:"
  end

  def test_help_flag
    @cli.call(["-h"])

    assert_includes @stdout.string, "Mirrorfile"
  end

  def test_version_flag
    @cli.call(["--version"])

    assert_includes @stdout.string, Mirrorfile::VERSION
  end

  def test_unknown_command_shows_usage
    @cli.call(["unknown"])

    assert_includes @stderr.string, "Usage:"
  end

  def test_no_command_shows_usage
    @cli.call([])

    assert_includes @stderr.string, "Usage:"
  end

  def test_returns_zero_on_success
    result = @cli.call(["help"])

    assert_equal 0, result
  end

  def test_returns_one_on_mirrorfile_not_found
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        result = @cli.call(["install"])

        assert_equal 1, result
        assert_includes @stderr.string, "Error:"
      end
    end
  end
end
