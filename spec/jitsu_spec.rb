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

  it "finds a build.jitsu file in the current directory"

  it "finds a build.jitsu file in the parent directory"
end
