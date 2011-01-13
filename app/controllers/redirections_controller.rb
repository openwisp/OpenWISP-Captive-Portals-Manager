class RedirectionsController < ApplicationController
  before_filter :load_captive_portal

  protected

  def load_captive_portal
    worker = BackgrounDRb::Railtie::MiddleMan.worker(:captive_portal_worker)

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
      redirection_url = @captive_portal.compile_redirection_url(
          :original_url => original_url,
          :mac_address => @client_mac,
          :ip_address => @client_ip
      )
      respond_to do |format|
        format.html { redirect_to redirection_url, :status => 302 }
      end
    end
  end

  def login
    original_url = params[:original_url].nil? ? CaptivePortal::DEFAULT_URL :
        URI.escape(params[:original_url])

    if params[:username].nil? or params[:password].nil? or
        params[:username].blank? or params[:password].blank?
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
