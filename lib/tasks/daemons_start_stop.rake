# This file is part of the OpenWISP Captive Portal Manager
#
# Copyright (C) 2011 CASPUR (wifi@caspur.it)
#
# This software is licensed under a Creative  Commons Attribution-NonCommercial
# 3.0 Unported License.
#   http://creativecommons.org/licenses/by-nc/3.0/
#
# Please refer to the  README.license  or contact the copyright holder (CASPUR)
# for licensing details.
#

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
