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

class OperatorSession < Authlogic::Session::Base
  generalize_credentials_error_messages I18n.t(:login_error)

  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end

  def persisted?
    false
  end
  
end
