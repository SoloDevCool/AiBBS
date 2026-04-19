class Admin::DashboardController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @total_users = User.real_users.count
    @admin_count = User.real_users.admin.count
    @regular_count = User.real_users.user.count
    @recent_users = User.real_users.order(created_at: :desc).limit(5)
  end

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "无权访问管理控制台"
    end
  end
end
