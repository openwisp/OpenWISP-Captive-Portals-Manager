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

#noinspection RubyResolve
class RedirectionsController < ApplicationController
  before_filter :set_headers
  before_filter :load_captive_portal

  protect_from_forgery :except => [ :login, :logout ]

  protected

  def set_headers
    # Prevents Keep-Alive and caching for CP error, redirect, login and logout 
    # HTTP Keep-Alive and Caching can interfere with aforementioned operations
    response.headers["Connection"] = "close"
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def load_captive_portal
    worker = MiddleMan.worker(:captive_portal_worker)

    @client_ip = request.remote_ip
    @interface = worker.get_interface(
        :args => {
            :address => @client_ip
        }
    )
    @client_mac = worker.get_host_mac_address(
        :args => {
            :address => @client_ip
        }
    )
    @captive_portal = CaptivePortal.find_by_cp_interface(@interface)
  end

  public

  def redirect
    original_url = request.url

    unless @captive_portal.nil?
      begin
        redirection_url = @captive_portal.compile_redirection_url(
          :original_url => original_url,
          :mac_address => @client_mac,
          :ip_address => @client_ip
        )
      rescue Exception => e
        # send exception via mail
        begin
          raise e, "Problem on @captive_portal.compile_redirection_url: #{e.message}", e.backtrace
        rescue Exception => modified_e
          ExceptionNotifier::Notifier.background_exception_notification(modified_e).deliver
        end
        # default to redirection_url
        redirection_url = @captive_portal.redirection_url
        if redirection_url.include?('?')
          redirection_url = redirection_url.split('?')[0]
        end
      end
      respond_to do |format|
        format.html { redirect_to redirection_url, :status => 302 }
      end
    else
      respond_to do |format|
        format.html { render :action => :unimplemented }
      end
    end
  end

  def login
    if @captive_portal.nil?
      respond_to do |format|
        format.html { render :action => :invalid_network }
      end
      return
    end

    original_url = params[:original_url].nil? ? CaptivePortal::DEFAULT_URL :
        URI.unescape(params[:original_url])
    
    # ensure username and password are not blank unless mac address authentication is enabled
    if !@captive_portal.mac_address_auth and (
       params[:username].nil? or params[:password].nil? or
       params[:username].blank? or params[:password].blank?
    )
      redirection_url = @captive_portal.compile_redirection_url(
          :original_url => original_url,
          :mac_address => @client_mac,
          :ip_address => @client_ip
      )
      respond_to do |format|
        format.html { redirect_to redirection_url, :status => 302 }
      end
    else
      cp_session_token, message = @captive_portal.authenticate_user(
          params[:username],
          params[:password],
          @client_ip,
          @client_mac
      )
      if ! cp_session_token.nil?
        cookies[:cp_session_token] = {
            :value => cp_session_token,
            :expires => 1.year.from_now
        }

        respond_to do |format|
          format.html { redirect_to original_url }
        end
      else
        error_url = @captive_portal.compile_error_url(
            :mac_address => @client_mac,
            :ip_address => @client_ip,
            :message => message,
            :original_url => original_url
        )
        respond_to do |format|
          format.html { redirect_to error_url }
        end
      end
    end
  end

  def logout
    if cookies[:cp_session_token].nil?
      Rails.logger.error("No cp_session_token cookie?!?")
      respond_to do |format|
        format.html { render :logout_error }
      end
    else
      user = @captive_portal.online_users.find_by_cp_session_token(cookies[:cp_session_token])
      if user.nil?
        Rails.logger.error("Invalid cp_session_token cookie, user not found!")
      else
        @captive_portal.deauthenticate_user(
            user,
            RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Explicit_logout]
        )
        user.destroy
      end
      cookies.delete(:cp_session_token)

      respond_to do |format|
        format.html { redirect_to CaptivePortal::DEFAULT_URL }
      end
    end
  end

  def default_authentication_page
    @original_url = params[:original_url]

    respond_to do |format|
      format.html { render :default_authentication_page }
    end
  end

  def default_error_page
    @message = params[:message] || t(:no_message)

    respond_to do |format|
      format.html { render :default_error_page }
    end
  end

end
