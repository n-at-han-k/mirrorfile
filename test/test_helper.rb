# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'mirrorfile'
require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'

ENV['MIRRORFILE_SKIP_GEM_UPDATE'] = '1'
