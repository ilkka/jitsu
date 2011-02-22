require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Target" do
  it "has a name" do
    Jitsu::Target.should respond_to :name
  end
end
