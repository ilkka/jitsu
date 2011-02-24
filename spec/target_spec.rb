require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Jitsu::Target do
  it "has inputs and outputs" do
    [:inputs, :outputs].each {|x| Jitsu::Target.public_instance_methods.should include x}
  end
end
