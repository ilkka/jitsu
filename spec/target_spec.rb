require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Target" do

  before :each do
    @t = Jitsu::Target.new(:name => "foo.o",
                          :type => "object",
                          :source => "foo.cpp",
                          :cxxflags => "-Wall -ansi -pedantic")
    @t2 = Jitsu::Target.new(:name => "foo",
                           :type => "executable",
                           :objects => [@t],
                           :ldflags => "-lbar")
  end

  it "has a name attribute" do
    Jitsu::Target.public_instance_methods.should include :name
    Jitsu::Target.public_instance_methods.should include :name=
    @t.name.should == "foo.o"
    @t2.name.should == "foo"
  end

  it "has a type attribute" do
    Jitsu::Target.public_instance_methods.should include :type
    Jitsu::Target.public_instance_methods.should include :type=
    @t.type.should == "object"
    @t2.type.should == "executable"
  end

  it "may have a source attribute if it is an object" do
    Jitsu::Target.public_instance_methods.should include :source
    Jitsu::Target.public_instance_methods.should include :source=
    @t.source.should == "foo.cpp"
    @t2.source.should be_nil
  end

  it "may have an objects attribute if it is a linked target" do
    Jitsu::Target.public_instance_methods.should include :objects
    Jitsu::Target.public_instance_methods.should include :objects=
    @t.objects.should == nil
    @t2.objects.should == [@t]
  end

  it "may have ldflags if it's a linked target" do
    @t.ldflags.should be_nil
    @t2.ldflags.should == "-lbar"
  end

  it "may have cxxflags if it's an object" do
    @t.cxxflags.should == "-Wall -ansi -pedantic"
    @t2.cxxflags.should be_nil
  end
end
