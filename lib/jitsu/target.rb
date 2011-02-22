module Jitsu

  # Target represents a buildable target.
  #
  class Target

    attr_accessor :name, :type, :source, :objects, :dependencies, :cxxflags, :ldflags

    # Create a new Target instance.
    #
    # @param conf [Hash] target configuration as read from the
    # jitsufile.
    def initialize(conf)
      super()
      set_from_conf(conf, :name, :type, :source, :objects, :dependencies, :cxxflags, :ldflags)
    end

    private

    def set_from_conf(conf, *settings)
      settings.each do |setting|
        self.send "#{setting.to_s}=", (conf[setting.to_sym] or conf[setting.to_s])
      end
    end

  end

end
