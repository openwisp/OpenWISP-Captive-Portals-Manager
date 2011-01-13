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
