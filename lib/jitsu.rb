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

  # Check if any of the targets needs libtool.
  #
  # @param targets [Enum] the targets from a build specification hash.
  # @return [Boolean] true if libtool required, nil otherwise.
  def self.libtool_needed_for(targets)
    not targets.select { |key,val| val['type'] == 'libtool_library' }.empty?
  end

  # Output jitsu build specification as build.ninja file(s).
  #
  # @param data [Hash] a build specification from e.g. Jitsu::read.
  # @return nil
  def self.output(data)
    File.open NINJA_FILE_NAME, 'w' do |f|
      libtool = libtool_needed_for data['targets']
      f.write <<-EOS
cxxflags =
ldflags =
cxx = g++
ld = g++
ar = ar
EOS
      if libtool
        f.write "libtool = libtool\n"
      end
      f.write <<-EOS

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
      if libtool_needed_for data['targets']
        f.write <<-EOS

rule ltcxx
  description = CC ${in}
  depfile = ${out}.d
  command = ${libtool} --mode=compile ${cxx} -MMD -MF ${out}.d ${cxxflags} -c ${in}

rule ltlink
  description = LD ${out}
  command = ${libtool} --mode=link ${ld} ${ldflags} -o ${out} ${in}
EOS
      end
      data['targets'].each do |target,conf|
        f.write "\n"
        sources = conf['sources']
        objects = sources_to_objects(sources).join(' ')
        Jitsu.send "handle_#{conf['type']}".to_sym, f, target, sources, objects, conf
      end
      f.write("\nbuild all: phony || #{data['targets'].keys.join(' ')}\n")
    end
  end

  # Output build rules for a list of sources.
  #
  # @param out [IO] the output stream where output is written.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param conf [Hash] the entire build spec hash for this target.
  def self.output_sources(out, sources, conf)
    cxxflags = conf['cxxflags']
    rule = (conf['type'] == 'libtool_library' ? "ltcxx" : "cxx")
    sources.each do |src|
      out.write "build #{source_to_object src}: #{rule} #{src}\n"
      out.write "  cxxflags = #{cxxflags}\n" if cxxflags
    end
  end

  # Output build rules for one executable target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [String] the filename of the target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param objects [Enumerable] a list of all object files for the target.
  # @param conf [Hash] the entire build spec hash for this target.
  def self.handle_executable(out, target, sources, objects, conf)
    output_sources(out, sources, conf)
    out.write "build #{target}: link #{objects}"
    out.write " #{conf['dependencies'].join(' ')}" if conf['dependencies']
    out.write "\n"
    out.write "  ldflags = #{conf['ldflags']}\n" if conf['ldflags']
  end

  # Output build rules for one static library target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [String] the filename of the target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param objects [Enumerable] a list of all object files for the target.
  # @param conf [Hash] the entire build spec hash for this target.
  def self.handle_static_library(out, target, sources, objects, conf)
    output_sources(out, sources, conf)
    out.write "build #{target}: archive #{objects}"
    out.write " #{conf['dependencies'].join(' ')}" if conf['dependencies']
    out.write "\n"
  end

  # Output build rules for one dynamic library target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [String] the filename of the target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param objects [Enumerable] a list of all object files for the target.
  # @param conf [Hash] the entire build spec hash for this target.
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

  # Convert sourcefile name to corresponding object file name.
  #
  # @param src [String] source file path.
  # @return [String] object file path.
  def self.source_to_object(src)
    src.gsub /\.[Cc]\w+$/, '.o'
  end

  # Convert a list of sourcefile names to corresponding object file names.
  #
  # @param srcs [Enumerable] source file paths.
  # @return [Enumerable] object file paths.
  def self.sources_to_objects(srcs)
    srcs.map { |src| source_to_object src }
  end
end
