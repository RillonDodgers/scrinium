class Admin::BaseController < ApplicationController
  before_action :authorize_admin

  private

  def authorize_admin
    authorize! :admin, with: AdminPolicy, to: :manage?
  end
end
