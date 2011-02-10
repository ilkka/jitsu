module Jitsu
  def self.ninja
    candidates = ENV['PATH'].split(/:/).map { |d| File.join d, 'ninja' }
    candidates.select { |n| File.executable? n }.first
  end
end
