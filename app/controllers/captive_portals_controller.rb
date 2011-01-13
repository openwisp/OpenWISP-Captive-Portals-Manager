class CaptivePortalsController < ApplicationController
  layout "operators"

  before_filter :require_operator

  before_filter :load_captive_portal, :only => [ :show, :destroy, :edit, :update ]

  protected

  def load_captive_portal
    @captive_portal = CaptivePortal.find(params[:id])
  end

  public

  def index
    @captive_portals = CaptivePortal.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @captive_portals }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @captive_portal }
    end
  end

  def new
    @captive_portal = CaptivePortal.new
    @captive_portal.radius_auth_server = RadiusAuthServer.new
    @captive_portal.radius_acct_server = RadiusAcctServer.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @captive_portal }
    end
  end

  def edit
    @captive_portal.radius_auth_server = RadiusAuthServer.new if @captive_portal.radius_auth_server.nil?
    @captive_portal.radius_acct_server = RadiusAcctServer.new if @captive_portal.radius_acct_server.nil?
  end

  def create
    @captive_portal = CaptivePortal.new(params[:captive_portal])

    @captive_portal.radius_auth_server = RadiusAuthServer.new if @captive_portal.radius_auth_server.nil?
    @captive_portal.radius_acct_server = RadiusAcctServer.new if @captive_portal.radius_acct_server.nil?
    
    respond_to do |format|
      if @captive_portal.save
        format.html { redirect_to(@captive_portal, :notice => 'Captive portal was successfully created.') }
        format.xml  { render :xml => @captive_portal, :status => :created, :location => @captive_portal }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @captive_portal.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    
    respond_to do |format|
      if @captive_portal.update_attributes(params[:captive_portal])
        format.html { redirect_to(@captive_portal, :notice => 'Captive portal was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @captive_portal.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @captive_portal.destroy

    respond_to do |format|
      format.html { redirect_to(captive_portals_url) }
      format.xml  { head :ok }
    end
  end

end
