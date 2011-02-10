module Jitsu
  # Get path to ninja.
  #
  # @return [String] path to `ninja` or nil if ninja was not found.
  def self.ninja
    candidates = ENV['PATH'].split(/:/).map { |d| File.join d, 'ninja' }
    candidates.select { |n| File.executable? n }.first
  end
end
