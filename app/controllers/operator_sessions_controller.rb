# This file is part of the OpenWISP Captive Portal Manager
#
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

class OperatorSessionsController < ApplicationController
  layout "operators"

  before_filter :require_no_operator, :only => [:new, :create]
  before_filter :require_operator, :only => :destroy

  def new
    @operator_session = OperatorSession.new
  end

  def create
    @operator_session = OperatorSession.new(params[:operator_session])
    if @operator_session.save
      redirect_back_or_default captive_portals_path, :notice => I18n.t(:login_successful)
    else
      render :action => :new
    end
  end

  def destroy
    current_operator_session.destroy
    redirect_back_or_default operator_login_url, :notice => I18n.t(:logout_successful)
  end
end
