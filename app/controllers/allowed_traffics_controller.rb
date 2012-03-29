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
