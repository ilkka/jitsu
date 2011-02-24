require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Jitsu::Target do
  it "has inputs and outputs" do
    [:inputs, :outputs].each {|x| Jitsu::Target.public_instance_methods.should include x}
  end

  it "can have other arbitrary data attached" do
    Flags1 = "-Wall -ansi -pedantic"
    t = Jitsu::Target.new :cxxflags => Flags1
    t[:cxxflags].should == Flags1
    Flags2 = "-O0 -g"
    t[:cxxflags] = Flags2
    t[:cxxflags].should == Flags2
  end
end
