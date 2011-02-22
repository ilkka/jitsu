require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Target" do
  it "has a name" do
    Jitsu::Target.public_instance_methods.should include :name
    t = Jitsu::Target.new(:name => "foo.o",
                          :type => "object",
                          :source => "foo.cpp",
                          :cxxflags => "-Wall -ansi -pedantic")
    t2 = Jitsu::Target.new(:name => "foo",
                           :type => "executable",
                           :objects => [t],
                           :ldflags => "-lbar")
    t.name.should == "foo.o"
    t.type.should == "object"
    t.source.should == "foo.cpp"
    t.cxxflags.should == "-Wall -ansi -pedantic"
    t.ldflags.should be_nil
    t2.name.should == "foo"
    t2.type.should == "executable"
    t2.objects.should == [t]
    t2.source.should be_nil
    t2.ldflags.should == "-lbar"
  end
end
