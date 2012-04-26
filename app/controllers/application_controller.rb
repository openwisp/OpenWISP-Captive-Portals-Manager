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

class ApplicationController < ActionController::Base
  # Set locale from session locale
  before_filter :set_locale

  protect_from_forgery

  helper :all
  helper_method :current_operator_session, :current_operator

  def set_locale
    I18n.locale = I18n.available_locales.include?(session[:locale]) ? session[:locale] : nil
  end

  def set_session_locale
    session[:locale] = params[:locale].to_sym
    redirect_to request.env['HTTP_REFERER'] || :root, :only_path => true
  end

  private

  def current_operator_session
    logger.debug "ApplicationController::current_operator_session"
    return @current_operator_session if defined?(@current_operator_session)
    @current_operator_session = OperatorSession.find
  end

  def current_operator
    logger.debug "ApplicationController::current_operator"
    return @current_operator if defined?(@current_operator)
    @current_operator = current_operator_session && current_operator_session.operator
  end

  def require_operator
    logger.debug "ApplicationController::require_operator"
    unless current_operator
      store_location
      redirect_to operator_login_url, :notice => I18n.t(:you_must_be_logged_in)
      
      false
    end
  end

  def require_no_operator
    logger.debug "ApplicationController::require_no_operator"
    if current_operator
      store_location
      redirect_to captive_portals_path, :notice => I18n.t(:you_must_be_logged_out)
      false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default, options = {})
    redirect_to(session[:return_to] || default, options)
    session[:return_to] = nil
  end
  
end
