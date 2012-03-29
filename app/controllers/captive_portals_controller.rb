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
