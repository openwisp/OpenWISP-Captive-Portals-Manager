#!/usr/bin/env ruby

RAILS_HOME = File.expand_path(File.join(File.dirname(__FILE__),".."))

require "rubygems"
require "active_support"
require "active_record"

require "yaml"
require "erb"
require "logger"
require "optparse"

require RAILS_HOME + "/config/boot"
require "backgroundrb"

BDRB_HOME = ::BackgrounDRb::BACKGROUNDRB_ROOT

["server","server/lib","lib","lib/backgroundrb"].each { |x| $LOAD_PATH.unshift(BDRB_HOME + "/#{x}")}

$LOAD_PATH.unshift(File.join(RAILS_HOME,"lib","workers"))

require "bdrb_config"

BDRB_CONFIG = BackgrounDRb::Config.read_config("#{RAILS_HOME}/config/backgroundrb.yml")

if !(::Packet::WorkerRunner::WORKER_OPTIONS[:worker_env] == false)
  require RAILS_HOME + "/config/environment"
end
require "backgroundrb_server"

