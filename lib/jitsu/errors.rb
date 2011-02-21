# Exception classes for Jitsu module
#
module Jitsu

  # Base class for Jitsu errors.
  # 
  class JitsuError < StandardError
  end

  # Jitsufile syntax error.
  #
  class SyntaxError < JitsuError

    # Construct a new SyntaxError.
    #
    # @param jitsufile [String] path to file where error happened.
    # @param msg [String] error message.
    # @param errors [Enumerable] list of errors from Kwalify, or nil.
    def initialize(jitsufile, msg, errors=nil)
      message = msg
      if errors and errors.is_a?(Enumerable)and not errors.empty?
      message << ":"
        errors.each do |err|
          message << "\n"
          message << (err.filename ? err.filename : jitsufile) << ":"
          message << (err.linenum ? "#{err.linenum}" : "0") << ":"
          message << err.path << " -- " << err.message
        end
      end
      super(message)
    end
  end

end
