require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Target" do
  it "has a name" do
    Jitsu::Target.public_instance_methods.should include :name
    Jitsu::Target.new("name" => "my special target").name.
      should == "my special target"
  end
end
