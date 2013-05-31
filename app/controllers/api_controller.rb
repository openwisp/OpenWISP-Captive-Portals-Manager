class ApiController < ApplicationController
  before_filter :authorize_ip, :only => [:login, :logout]

  def login
    # only allow POST requests
    if request.method != 'POST'
      result = { :errors => I18n.t('api.method_not_allowed') }
      status = 405
    # username and password must be supplied
    elsif params[:username].nil? or params[:password].nil?
      result = { :errors => I18n.t('api.params_missing') }
      status = 400
    else
      # if no ip specified the current client ip is assumed
      load_captive_portal(params[:ip] || request.remote_ip)

      # no ip address associated
      if @captive_portal.nil?
        result = { :errors => I18n.t('api.ip_address_not_associated') }
        status = 403

      # try to login the user
      else
        @cp_session_token, @message = @captive_portal.authenticate_user(
          params[:username],
          params[:password],
          @client_ip,
          @client_mac,
          params[:timeout] ? params[:timeout] : false
        )

        # invalid username or password
        if !@message.nil? and @message.include?('Invalid username or password')
          result = { :errors => I18n.t('api.invalid_username_password') }
          status = 403
        # success!
        else
          result = { :detail => I18n.t('api.logged_in'), :session_id => @cp_session_token }
          status = 200
        end
      end
    end

    respond_to do |format|
      format.html { render :json => result, :status => status }
      format.xml  { render :xml  => result, :status => status }
      format.json { render :json => result, :status => status }
      format.any  { render :text => I18n.t('api.format_not_supported'), :status => 406 }
    end
  end

  def logout
    if request.method != 'POST'
      result = { :errors => I18n.t('api.method_not_allowed') }
      status = 405
    elsif params[:username].nil?
      result = { :errors => I18n.t('api.params_missing') }
      status = 400
    else
      load_captive_portal(params[:ip] || request.remote_ip)
      if @captive_portal.nil?
        result = { :errors => I18n.t('api.ip_address_not_associated') }
        status = 403
      else
        user = @captive_portal.online_users.find_by_username(params[:username])
        if user.nil?
          result = { :errors => I18n.t('api.username_not_logged_in') }
          status = 403
        else
          @captive_portal.deauthenticate_user(
              user,
              RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Explicit_logout]
          )
          user.destroy
          result = { :detail => I18n.t('api.logged_out_successfully') }
          status = 200
        end
      end
    end
    respond_to do |format|
      format.html { render :json => result, :status => status }
      format.xml  { render :xml  => result, :status => status }
      format.json { render :json => result, :status => status }
      format.any  { render :text => I18n.t('api.format_not_supported'), :status => 406 }
    end
  end

  private

  def load_captive_portal(ip)
    worker = MiddleMan.worker(:captive_portal_worker)

    @client_ip = ip
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

  def authorize_ip
    # if trying to login a specific IP we must be authorized
    # is ip param is not specified then no problem, a user is trying to authenticate himself against the API
    if not params[:ip].nil? and not CONFIG['api_allowed_ips'].include?(request.remote_ip)
      render :text => I18n.t('api.ip_address_not_allowed'), :status => 403
      return false
    end
  end
end