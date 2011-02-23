require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Jitsu" do
  it "finds ninja if ninja is in PATH" do
    File.executable?(Jitsu.ninja).should be_true
  end

  it "fails to find ninja if ninja is not in PATH" do
    oldpath = ENV['PATH']
    ENV['PATH'] = ""
    Jitsu.ninja.should == nil
    ENV['PATH'] = oldpath
  end

  it "finds no jitsu file if a jitsu file is not present" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        Jitsu.jitsufile.should == nil
      end
    end
  end

  it "finds a build.jitsu file in the current directory" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open('build.jitsu', 'w') do |f|
          f.write 'fuubar'
          Jitsu.jitsufile.should == 'build.jitsu'
        end
      end
    end
  end

  it "finds a build.jitsu file in the parent directory" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open('build.jitsu', 'w') do |f|
          f.write 'fuubar'
        end
        Dir.mkdir 'subdir'
        Dir.chdir 'subdir' do |dir|
          Jitsu.jitsufile.should == '../build.jitsu'
        end
      end
    end
  end

  it "reads YAML from jitsu files" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  - name: test1
    type: executable
    sources:
      - test1.cpp
    cxxflags: -g -Wall
    dependencies:
      - test2
  - name: test2
    type: static_library
    sources:
      - test2.cpp
    cxxflags: -ansi -pedantic
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        data['targets'].map { |x| x['name'] }.should == ['test1', 'test2']
      end
    end
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  - name: aaa1
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
    cxxflags: -g -Wall
    dependencies:
      - aaa2
  - name: aaa2
    type: dynamic_library
    sources:
      - aaa2.cpp
    cxxflags: -ansi -pedantic
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        data['targets'].map { |x| x['name'] }.should == ['aaa1', 'aaa2']
      end
    end
  end

  it "correctly converts build specs into Targets" do
    spec = YAML.load <<-EOS
---
targets:
  - name: aaa1
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
EOS
    targets = Jitsu.spec_to_targets(spec)
    targets.keys.should == ['aaa1a.o', 'aaa1b.o', 'aaa1']
    targets['aaa1'].objects.map {|o| o.name}.should == ['aaa1a.o', 'aaa1b.o']
    targets['aaa1a.o'].source.should == 'aaa1a.cpp'
    targets['aaa1b.o'].source.should == 'aaa1b.cpp'
  end

  it "outputs a build.jitsu file" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  - name: aaa1
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
    dependencies:
      - aaa2.a
      - aaa3.so
  - name: aaa2.a
    type: static_library
    sources: 
      - aaa2.cpp
    cxxflags: -ansi -pedantic
  - name: aaa3.so
    type: dynamic_library
    sources:
      - aaa3.cpp
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        Jitsu.output data
        Dir['build.ninja'].length.should == 1
        ninjafile = <<-EOS
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

build aaa1a.o: cxx aaa1a.cpp
build aaa1b.o: cxx aaa1b.cpp
build aaa1: link aaa1a.o aaa1b.o aaa2.a aaa3.so

build aaa2.o: cxx aaa2.cpp
  cxxflags = -ansi -pedantic
build aaa2.a: archive aaa2.o

build aaa3.o: cxx aaa3.cpp
  cxxflags = ${cxxflags} -fPIC
build aaa3.so: link aaa3.o
  ldflags = ${ldflags} -shared -Wl,-soname,aaa3.so

build all: phony || aaa1 aaa2.a aaa3.so
EOS
        File.open('build.ninja', 'r').read.should == ninjafile
      end
    end
  end

  it "outputs a build.jitsu file with libtool" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  - name: aaa1
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
    dependencies:
      - aaa2.a
      - aaa3.la
  - name: aaa2.a
    type: static_library
    sources: 
      - aaa2.cpp
    cxxflags: -ansi -pedantic
  - name: aaa3.la
    type: libtool_library
    sources:
      - aaa3.cpp
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        Jitsu.output data
        Dir['build.ninja'].length.should == 1
        ninjafile = <<-EOS
cxxflags =
ldflags =
cxx = g++
ld = g++
ar = ar
libtool = libtool

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

rule ltcxx
  description = CC ${in}
  depfile = ${out}.d
  command = ${libtool} --quiet --mode=compile ${cxx} -MMD -MF ${out}.d ${cxxflags} -c ${in}

rule ltlink
  description = LD ${out}
  command = ${libtool} --quiet --mode=link ${ld} ${ldflags} -o ${out} ${in}

build aaa1a.o: cxx aaa1a.cpp
build aaa1b.o: cxx aaa1b.cpp
build aaa1: ltlink aaa1a.o aaa1b.o aaa2.a aaa3.la

build aaa2.o: cxx aaa2.cpp
  cxxflags = -ansi -pedantic
build aaa2.a: archive aaa2.o

build aaa3.lo: ltcxx aaa3.cpp
build aaa3.la: ltlink aaa3.lo
  ldflags = ${ldflags} -rpath /usr/local/lib

build all: phony || aaa1 aaa2.a aaa3.la
EOS
        File.open('build.ninja', 'r').read.should == ninjafile
      end
    end
  end

  it "outputs a build.jitsu file without duplicated rules" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  - name: a
    type: executable
    sources:
      - a.cpp
      - b.cpp
  - name: b
    type: executable
    sources: 
      - b.cpp
      - c.cpp
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        Jitsu.output data
        File.read('build.ninja').scan(/^build b\.o:/).count.should == 1
      end
    end
  end
end
