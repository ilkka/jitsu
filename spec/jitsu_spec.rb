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
  test1:
    type: executable
    sources: test1.cpp
    cppflags: -g -Wall
    dependencies:
      - test2
  test2:
    type: library
    sources: test2.cpp
    cppflags: -ansi -pedantic
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        data['targets'].keys.should == ['test1', 'test2']
      end
    end
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  aaa1:
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
    cppflags: -g -Wall
    dependencies:
      - aaa2
  aaa2:
    type: library
    sources: aaa2.cpp
    cppflags: -ansi -pedantic
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        data['targets'].keys.should == ['aaa1', 'aaa2']
      end
    end
  end

  it "outputs a build.jitsu file" do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do |dir|
        File.open 'build.jitsu', 'w' do |f|
          f.write <<-EOS
---
targets:
  aaa1:
    type: executable
    sources:
      - aaa1a.cpp
      - aaa1b.cpp
    cppflags: -g -Wall
    dependencies:
      - aaa2
  aaa2:
    type: library
    sources: aaa2.cpp
    cppflags: -ansi -pedantic
EOS
        end
        data = Jitsu.read Jitsu.jitsufile
        Jitsu.output data
        Dir['build.ninja'].length.should == 1
      end
    end
  end
end
