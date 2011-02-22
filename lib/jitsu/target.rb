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

    # Convert to string
    #
    # @return [String] ninja rules for building this target.
    def to_s
      str = ""
      str << "build #{name}: "
      str << case type
             when "executable", "dynamic_library"
               "link #{objects.map {|o| o.name}.join ' '}"
             when "static_library"
               "archive #{objects.map {|o| o.name}.join ' '}"
             when "object"
               "cxx #{source}"
             end
      str << " #{dependencies.map {|dep| dep.name}.join(' ')}" if dependencies
      str << "\n"
      str << "  cxxflags = " + cxxflags + "\n" if cxxflags
      str << "  ldflags = " + ldflags + "\n" if ldflags
      str
    end

    # Compare target to other target.
    #
    # @param other [Target] the other target.
    # @return [Boolean] true if the targets are the same, false otherwise.
    def ==(other)
      [:class, :cxxflags, :ldflags, :type, :source, :name].all? do |attr|
        other.send(attr) == self.send(attr)
      end
    end

    private

    def set_from_conf(conf, *settings)
      settings.each do |setting|
        self.send "#{setting.to_s}=", (conf[setting.to_sym] or conf[setting.to_s])
      end
    end

  end

end
