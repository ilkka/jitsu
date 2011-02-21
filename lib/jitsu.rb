require 'yaml'
require 'kwalify'

require 'jitsu/errors'

# Main Jitsu module.
#
# Usage:
#
#   Dir.chdir 'directory-with-jitsufiles'
#   Jitsu.work
module Jitsu
  JITSU_FILE_NAME = 'build.jitsu'
  NINJA_FILE_NAME = 'build.ninja'

  # Process jitsufiles in current directory.
  #
  def self.work
    Jitsu.output(Jitsu.read(Jitsu.jitsufile))
  end

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
    schema = YAML.load_file(File.join(File.dirname(__FILE__), 'schema.yaml'))
    validator = Kwalify::Validator.new(schema)
    parser = Kwalify::Yaml::Parser.new(validator)
    doc = parser.parse(File.read(jitsufile))
    if parser.errors and not parser.errors.empty?
      raise Jitsu::SyntaxError.new("Syntax error", parser.errors)
    end
    doc
  end

  # Check if any of the targets needs libtool.
  #
  # @param targets [Enum] the targets from a build specification hash.
  # @return [Boolean] true if libtool required, nil otherwise.
  def self.libtool_needed_for(targets)
    not targets.select { |target| target['type'] == 'libtool_library' }.empty?
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
  command = ${libtool} --quiet --mode=compile ${cxx} -MMD -MF ${out}.d ${cxxflags} -c ${in}

rule ltlink
  description = LD ${out}
  command = ${libtool} --quiet --mode=link ${ld} ${ldflags} -o ${out} ${in}
EOS
      end
      data['targets'].each do |target|
        f.write "\n"
        sources = target['sources']
        Jitsu.send "handle_#{target['type']}".to_sym, f, target, sources, data['targets']
      end
      f.write("\nbuild all: phony || #{data['targets'].map { |t| t['name'] }.join(' ')}\n")
    end
  end

  # Output build rules for a list of sources.
  #
  # @param out [IO] the output stream where output is written.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param target [Hash] the entire build spec hash for this target.
  def self.output_sources(out, sources, target)
    cxxflags = target['cxxflags']
    libtool = target['type'] == 'libtool_library'
    rule = (libtool ? "ltcxx" : "cxx")
    sources.each do |src|
      object = (libtool ? source_to_ltobject(src) : source_to_object(src))
      out.write "build #{object}: #{rule} #{src}\n"
      out.write "  cxxflags = #{cxxflags}\n" if cxxflags
    end
  end

  # Output build rules for one executable target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [Hash] the entire build spec hash for this target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param targets [Hash] all targets for the build
  def self.handle_executable(out, target, sources, targets)
    output_sources(out, sources, target)
    libtool = libtool_needed_for targets.select { |tgt|
      target['dependencies'] and target['dependencies'].include? tgt['name']
    }
    rule = libtool ? "ltlink" : "link"
    out.write "build #{target['name']}: #{rule} #{sources_to_objects(sources).join ' '}"
    out.write " #{target['dependencies'].join(' ')}" if target['dependencies']
    out.write "\n"
    out.write "  ldflags = #{target['ldflags']}\n" if target['ldflags']
  end

  # Output build rules for one static library target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [Hash] the entire build spec hash for this target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param targets [Hash] all targets for the build
  def self.handle_static_library(out, target, sources, targets)
    output_sources(out, sources, target)
    out.write "build #{target['name']}: archive #{sources_to_objects(sources).join ' '}"
    out.write " #{target['dependencies'].join(' ')}" if target['dependencies']
    out.write "\n"
  end

  # Output build rules for one dynamic library target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [Hash] the entire build spec hash for this target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param targets [Hash] all targets for the build
  def self.handle_dynamic_library(out, target, sources, targets)
    target['cxxflags'] ||= '${cxxflags}'
    target['cxxflags'] += ' -fPIC'
    output_sources(out, sources, target)
    out.write "build #{target['name']}: link #{sources_to_objects(sources).join ' '}"
    out.write " #{target['dependencies'].join(' ')}" if target['dependencies']
    out.write "\n"
    target['ldflags'] ||= '${ldflags}'
    target['ldflags'] += " -shared -Wl,-soname,#{target['name']}"
    out.write "  ldflags = #{target['ldflags']}\n"
  end

  # Output build rules for one libtool library target.
  #
  # @param out [IO] the output stream where output is written.
  # @param target [Hash] the entire build spec hash for this target.
  # @param sources [Enumerable] a list of sourcefile names to output rules
  # for.
  # @param targets [Hash] all targets for the build
  def self.handle_libtool_library(out, target, sources, targets)
    output_sources(out, sources, target)
    out.write "build #{target['name']}: ltlink #{sources_to_ltobjects(sources).join ' '}"
    out.write " #{target['dependencies'].join(' ')}" if target['dependencies']
    out.write "\n"
    target['ldflags'] ||= '${ldflags}'
    target['ldflags'] += " -rpath /usr/local/lib"
    out.write "  ldflags = #{target['ldflags']}\n"
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

  # Convert sourcefile name to corresponding libtool object file name.
  #
  # @param src [String] source file path.
  # @return [String] libtool object file path.
  def self.source_to_ltobject(src)
    src.gsub /\.[Cc]\w+$/, '.lo'
  end

  # Convert a list of sourcefile names to corresponding libtool object file
  # names.
  #
  # @param srcs [Enumerable] source file paths.
  # @return [Enumerable] libtool object file paths.
  def self.sources_to_ltobjects(srcs)
    srcs.map { |src| source_to_ltobject src }
  end
end
