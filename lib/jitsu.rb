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
    while File.expand_path(File.join(dir, '..')) != File.expand_path(dir) do
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
ar = ar

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
        f.write "\n"
        sources = conf['sources']
        objects = sources_to_objects(sources).join(' ')
        Jitsu.send "handle_#{conf['type']}".to_sym, f, target, sources, objects, conf
      end
      f.write("\nbuild all: phony || #{data['targets'].keys.join(' ')}\n")
    end
  end

  def self.output_sources(out, sources, conf)
    cxxflags = conf['cxxflags']
    sources.each do |src|
      out.write "build #{source_to_object src}: cxx #{src}\n"
      out.write "  cxxflags = #{cxxflags}\n" if cxxflags
    end
  end

  def self.handle_executable(out, target, sources, objects, conf)
    output_sources(out, sources, conf)
    out.write "build #{target}: link #{objects}"
    out.write " #{conf['dependencies'].join(' ')}" if conf['dependencies']
    out.write "\n"
    out.write "  ldflags = #{conf['ldflags']}\n" if conf['ldflags']
  end

  def self.handle_static_library(out, target, sources, objects, conf)
    output_sources(out, sources, conf)
    out.write "build #{target}: archive #{objects}"
    out.write " #{conf['dependencies'].join(' ')}" if conf['dependencies']
    out.write "\n"
  end

  def self.handle_dynamic_library(out, target, sources, objects, conf)
    conf['cxxflags'] ||= '${cxxflags}'
    conf['cxxflags'] += ' -fPIC'
    output_sources(out, sources, conf)
    out.write "build #{target}: link #{objects}"
    out.write " #{conf['dependencies'].join(' ')}" if conf['dependencies']
    out.write "\n"
    conf['ldflags'] ||= '${ldflags}'
    conf['ldflags'] += " -shared -Wl,-soname,#{target}"
    out.write "  ldflags = #{conf['ldflags']}\n"
  end

  def self.source_to_object(src)
    src.gsub /\.[Cc]\w+$/, '.o'
  end

  def self.sources_to_objects(srcs)
    srcs.map { |src| source_to_object src }
  end
end
