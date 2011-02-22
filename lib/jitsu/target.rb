module Jitsu

  # Target represents a buildable target.
  #
  class Target

    attr_accessor :name

    # Create a new Target instance.
    #
    # @param conf [Hash] target configuration as read from the
    # jitsufile.
    def initialize(conf)
      self.name = (conf[:name] or conf['name'])
    end

  end

end
