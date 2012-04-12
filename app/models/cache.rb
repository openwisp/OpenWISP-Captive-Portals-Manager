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
    @cache_semaphore = Mutex.new
    @cache = {}
    @duration = duration
  end

  def []=(key, value)
    @cache_semaphore.lock

    @cache[key] = { :value => value, :expire_date => Time.now + @duration }
    return value

  ensure
    @cache_semaphore.unlock
  end

  def [](key)
    @cache_semaphore.lock

    elem = @cache[key]

    if elem.nil? || elem[:expire_date] < Time.now
      @cache.delete key
      return nil
    else
      return @cache[key][:value]
    end

  ensure
    @cache_semaphore.unlock
  end

end
