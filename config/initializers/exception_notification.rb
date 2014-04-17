ExceptionNotifier::Notifier.prepend_view_path File.join(Rails.root, 'app/views')

recipients = CONFIG['exception_notification_recipients'].split(',') rescue 'root@localhost'
sender = CONFIG['exception_notification_sender'] or 'owcpm@localhost'
email_subject_prefix = CONFIG['exception_notification_prefix'] or 'OWCPM'

Railscp::Application.config.middleware.use(
  ExceptionNotifier,
  :email_prefix => email_subject_prefix << ' ',
  :sender_address => sender,
  :exception_recipients => recipients,
  :sections =>  %w(request session environment backtrace)
)