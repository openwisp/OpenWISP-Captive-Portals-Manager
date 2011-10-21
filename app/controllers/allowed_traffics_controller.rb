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

class AllowedTrafficsController < ApplicationController
  layout "operators"

  before_filter :require_operator
  
  before_filter :load_captive_portal
  before_filter :load_allowed_traffic, :only => [ :show, :destroy, :edit, :update ]

  protected

  def load_captive_portal
    @captive_portal = CaptivePortal.find(params[:captive_portal_id])
  end

  def load_allowed_traffic
    @allowed_traffic = @captive_portal.allowed_traffics.find(params[:id])
  end

  public

  def index
    @allowed_traffics = @captive_portal.allowed_traffics.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @allowed_traffics }
    end
  end

  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @allowed_traffic }
    end
  end

  def new
    @allowed_traffic = @captive_portal.allowed_traffics.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @allowed_traffic }
    end
  end

  def edit
  end

  def create
    @allowed_traffic = @captive_portal.allowed_traffics.build(params[:allowed_traffic])

    respond_to do |format|
      if @allowed_traffic.save
        format.html {
          redirect_to(captive_portal_allowed_traffic_url(@captive_portal, @allowed_traffic),
                      :notice => 'Allowed traffic was successfully created.')
        }
        format.xml  { render :xml => @allowed_traffic, :status => :created, :location => @allowed_traffic }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @allowed_traffic.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @allowed_traffic.update_attributes(params[:allowed_traffic])
        format.html {
          redirect_to(captive_portal_allowed_traffic_url(@captive_portal, @allowed_traffic),
                      :notice => 'Allowed traffic was successfully updated.')
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @allowed_traffic.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @allowed_traffic.destroy

    respond_to do |format|
      format.html {
        redirect_to(captive_portal_allowed_traffics_url(@captive_portal))
      }
      format.xml  { head :ok }
    end
  end
end
