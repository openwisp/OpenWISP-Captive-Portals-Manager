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

class OnlineUsersController < ApplicationController
  layout "operators"

  before_filter :require_operator

  before_filter :load_captive_portal
  before_filter :load_online_user, :only => [ :show, :destroy ]

  protected

  def load_captive_portal
    @captive_portal = CaptivePortal.find(params[:captive_portal_id])
  end

  def load_online_user
    @online_user = @captive_portal.online_users.find(params[:id])
    @online_user.refresh! unless @online_user.nil?
  end

  public

  def index
    @online_users = @captive_portal.online_users.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @online_users }
    end
  end

  def show
    @online_user = @captive_portal.online_users.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @online_user }
    end
  end

  def destroy
    @captive_portal.deauthenticate_user(@online_user, RadiusAcctServer::SESSION_TERMINATE_CAUSE[:Forced_logout])
    @online_user.destroy

    respond_to do |format|
      format.html {
        redirect_to(captive_portal_online_users_url(@captive_portal))
      }
      format.xml  { head :ok }
    end
  end
end
