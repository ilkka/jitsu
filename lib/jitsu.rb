require 'yaml'

module Jitsu
  JITSU_FILE_NAME = 'build.jitsu'

  # Get path to ninja.
  #
  # @return [String] path to `ninja` or nil if ninja was not found.
  def self.ninja
    candidates = ENV['PATH'].split(/:/).map { |d| File.join d, 'ninja' }
    candidates.select { |n| File.executable? n }.first
  end

  # Get path to jitsu file. Search starting from current working
  # directory upwards.
  #
  # @return [String] path to jitsu file or nil if not found.
  def self.jitsufile
    dir = '.'
    while File.expand_path(dir) != '/' do
      candidate = Dir[File.join dir, JITSU_FILE_NAME].first
      if candidate and File.readable? candidate
        return candidate.gsub /^\.\//, ''
      end
      dir = File.join dir, '..'
    end
  end

  # Read a jitsu file and output the build specification.
  #
  # @param jitsufile [String] path to jitsu file from e.g. Jitsu::jitsufile.
  # @return [Hash] a hash of the build specification.
  def self.read(jitsufile)
    YAML.load(File.open(jitsufile, 'r').read)
  end
end
