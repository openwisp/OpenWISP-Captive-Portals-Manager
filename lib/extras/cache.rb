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

  def initialize(options = {})
    @cache_semaphore = Mutex.new
    @cache = {}
    @duration = options[:expires_in] || 10
  end

  def fetch(key)
    @cache_semaphore.lock

    @cache.delete_if { |_key, cached| cached[:expire_date] < Time.now }

    unless defined? @cache[key][:value]
      @cache[key] = {:value => yield, :expire_date => Time.now + @duration}
    end

    @cache[key][:value]

  ensure
    @cache_semaphore.unlock
  end

end
