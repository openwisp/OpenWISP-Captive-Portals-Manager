ExceptionNotifier::Notifier.prepend_view_path File.join(Rails.root, 'app/views')

recipients = CONFIG['exception_notification_recipients'].split(',') rescue false
sender = CONFIG['exception_notification_sender'] or 'owcpm@localhost'
email_subject_prefix = CONFIG['exception_notification_prefix'] or 'OWCPM'

if recipients
  Railscp::Application.config.middleware.use(
    ExceptionNotifier,
    :email_prefix => email_subject_prefix << ' ',
    :sender_address => sender,
    :exception_recipients => recipients,
    :sections =>  %w(request session environment backtrace),
    :ignore_if => lambda { |env, e| e.message =~ /^to_sym/ }
  )
end
