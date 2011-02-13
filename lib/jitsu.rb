require 'yaml'

module Jitsu
  JITSU_FILE_NAME = 'build.jitsu'
  NINJA_FILE_NAME = 'build.ninja'

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

  # Output jitsu build specification as build.ninja file(s).
  #
  # @param data [Hash] a build specification from e.g. Jitsu::read.
  # @return nil
  def self.output(data)
    File.open NINJA_FILE_NAME, 'w' do |f|
      f.write <<-EOS
cxxflags =
ldflags =
cxx = g++
ld = g++

rule cxx
  description = CC ${in}
  depfile = ${out}.d
  command = ${cxx} -MMD -MF ${out}.d ${cxxflags} -c ${in} -o ${out}

rule link
  description = LD ${out}
  command = ${ld} ${ldflags} -o ${out} ${in}

rule archive
  description = AR ${out}
  command = ${ar} rT ${out} ${in}

EOS
      data['targets'].each do |target,conf|
        sources = conf['sources']
        sources = [sources] if sources.is_a? String
        sources.each do |src|
          f.write "build #{src.gsub /\.[Cc]\w+$/, '.o'}: cxx #{src}\n"
          if conf['cxxflags']
            f.write "  cxxflags = #{conf['cxxflags']}\n"
          end
        end
      end
    end
  end
end
