class OperatorSession < Authlogic::Session::Base
  generalize_credentials_error_messages I18n.t(:login_error)

  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end

  def persisted?
    false
  end
  
end
