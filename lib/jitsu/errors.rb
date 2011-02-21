# Exception classes for Jitsu module
#
module Jitsu

  class JitsuError < StandardError
  end

  class SyntaxError < JitsuError
    def initialize(msg, errors=nil)
      message = msg
      message << ":\n"
      if errors and errors.is_a?(Enumerable)and not errors.empty?
        errors.each do |err|
          message << "  " << err.path << ":" << err.message << "\n"
        end
      end
      super(message)
    end
  end

end
