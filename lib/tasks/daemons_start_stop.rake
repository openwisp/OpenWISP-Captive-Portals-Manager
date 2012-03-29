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
  desc "Start deamons required to run OWCPM"
  task :start => :environment do
    puts 'Starting BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb start]

    Rake::Task['daemons:status'].execute
  end

  desc "Stop deamons required to run OWCPM"
  task :stop => :environment do
    puts 'Stopping BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb stop]

    Rake::Task['daemons:status'].execute
  end

  desc "Restart deamons required to run OWCPM"
  task :restart => :environment do
    puts 'Restarting OWCPM daemons...'
    Rake::Task['daemons:stop'].execute
    sleep 3
    Rake::Task['daemons:start'].execute
  end

  desc "Status of daemons required to run OWCPM"
  task :status => :environment do
    print 'BackgrounDRb: '
    %x[bundle exec #{Rails.root}/script/backgroundrb status]
    puts $? == 0 ? 'running...' : 'not running...'
    exit(1) if $? != 0
  end
end
