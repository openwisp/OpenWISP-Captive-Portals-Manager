# This file is part of the OpenWISP Captive Portal Manager
#
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

require 'active_support'

# Logger class for custom logging format
class CustomLogger < ActiveSupport::BufferedLogger

  private

    # CustomLogger doesn't define strings for log levels
    # so we have to do it ourselves
    def severity_string(level)
        case level
        when DEBUG
            :DEBUG
        when INFO
            :INFO
        when WARN
            :WARN
        when ERROR
            :ERROR
        when FATAL
            :FATAL
        else
            :UNKNOWN
        end
    end

  public

    # monkey patch the CustomLogger add method so that
    # we can format the log messages the way we want
    def add(severity, message = nil, progname = nil, &block)
        return if @level > severity
        message = (message || (block && block.call) || progname).to_s
        # If a newline is necessary then create a new message ending with a newline.
        # Ensures that the original message is not mutated.
        message = "[%5s %s ] %s\n" % [severity_string(severity),
                            Time.now.strftime("%m/%d %H:%M:%S"),
                            message] unless message[-1] == ?\n
        buffer << message
        auto_flush
        message
    end

end
