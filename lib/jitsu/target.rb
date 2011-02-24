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

  # Class representing a build system target.
  # 
  class Target

    attr_accessor :inputs, :outputs

    # Create a new Target instance. Arbitrary configuration can be passed as
    # :key => value pairs.
    #
    # @param args [Hash] configuration data.
    def initialize(args = {})
      @params = args
    end

    # Access configuration variable by name.
    #
    # @param key [Sym] the key for the configuration variable.
    # @return [] corresponding value.
    def [] (key)
      @params[key]
    end

    # Store configuration variable by name.
    #
    # @param key [Sym] the key for the configuration variable.
    # @param value [] the new value to store.
    def []= (key, value)
      @params[key] = value
    end

  end

end
