# Jitsu, a meta build system for Ninja
# Copyright (C) 2011 Ilkka Laukkanen <ilkka.s.laukkanen@gmail.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

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
