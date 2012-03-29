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

class LocalUsersController < ApplicationController
  layout "operators"

  before_filter :require_operator

  before_filter :load_captive_portal
  before_filter :load_local_user, :only => [ :show, :destroy, :edit, :update ]

  protected

  def load_captive_portal
    @captive_portal = CaptivePortal.find(params[:captive_portal_id])
  end

  def load_local_user
    @local_user = @captive_portal.local_users.find(params[:id])
  end

  public

  def index
    @local_users = @captive_portal.local_users.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @local_users }
    end
  end

  def show

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @local_user }
    end
  end

  def new
    @local_user = @captive_portal.local_users.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @local_user }
    end
  end

  def edit
  end

  def create
    @local_user = @captive_portal.local_users.build(params[:local_user])

    respond_to do |format|
      if @local_user.save
        format.html {
          redirect_to(captive_portal_local_user_url(@captive_portal, @local_user),
                      :notice => 'Local user was successfully created.')
        }
        format.xml  { render :xml => @local_user, :status => :created, :location => @local_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @local_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @local_user.update_attributes(params[:local_user])
        format.html {
          redirect_to(captive_portal_local_user_url(@captive_portal, @local_user), 
                      :notice => 'Local user was successfully updated.')
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @local_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @local_user.destroy

    respond_to do |format|
      format.html {
        redirect_to(captive_portal_local_users_url(@captive_portal))
      }
      format.xml  { head :ok }
    end
  end
end
