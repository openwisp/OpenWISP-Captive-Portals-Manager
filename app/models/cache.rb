# This file is part of the OpenWISP Captive Portal Manager
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Cache

  def initialize(duration = 10)
    @cache = {}
    @duration = duration
  end

  def []=(key, value)
    @cache[key] = { :value => value, :expire_date => Time.now + @duration }
    value
  end

  def [](key)
    elem = @cache[key]

    if elem.nil? || elem[:expire_date] < Time.now
      @cache.delete key
      nil
    else
      @cache[key][:value]
    end
  end

end