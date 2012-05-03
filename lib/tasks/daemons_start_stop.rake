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

namespace :daemons do

  def backgroundrb_status
    print 'BackgrounDRb: '
    %x[bundle exec #{Rails.root}/script/backgroundrb status]
    puts $? == 0 ? 'running...' : 'not running...'
    $?
  end

  def backgroundrb_start
    puts 'Starting BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb start]
    $?
  end

  def backgroundrb_stop
    puts 'Stopping BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb stop]
    $?
  end


  desc "Start deamons required to run OWCPM"
  task :start => :environment do
    backgroundrb_start
    backgroundrb_status
  end

  desc "Stop deamons required to run OWCPM"
  task :stop => :environment do
    backgroundrb_stop
    backgroundrb_status
  end

  desc "Restart deamons required to run OWCPM"
  task :restart => :environment do
    puts 'Restarting OWCPM daemons...'
    begin
      backgroundrb_stop
      sleep 1
    end while backgroundrb_status == 0
    backgroundrb_start
    exit(backgroundrb_status)
  end

  desc "Status of daemons required to run OWCPM"
  task :status => :environment do
    exit(1) if backgroundrb_status != 0
  end
end
