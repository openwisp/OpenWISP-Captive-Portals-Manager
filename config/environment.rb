# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Railscp::Application.initialize!

if Rails.env == 'production'
  require 'exception_notifier'

  Railscp::Application.config.middleware.use ExceptionNotifier,
           :email_prefix => "[Whatever] ",
           :sender_address => %{"notifier" <notifier@example.com>},
           :exception_recipients => %w{exceptions@example.com}
end

require 'custom_logger'

Railscp::Application.config.log_level = Rails.env=='production' ?
    ActiveSupport::BufferedLogger::Severity::INFO :
    ActiveSupport::BufferedLogger::Severity::DEBUG

# TODO: find a more reliable path for logging
Railscp::Application.config.logger = CustomLogger.new(Railscp::Application.config.paths.log.paths[0],
                                                      Railscp::Application.config.log_level)

Rails.logger.level = Railscp::Application.config.log_level
Rails.logger = Railscp::Application.config.logger