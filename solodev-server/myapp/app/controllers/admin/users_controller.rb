class Admin::UsersController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: :update

  def index
    @collection = User.real_users.order(created_at: :desc)
    @pagy, @users = pagy(:offset, @collection, limit: 15)
  end

  def update
    if params[:role].present? && User.roles.key?(params[:role])
      @user.update!(role: params[:role])
      redirect_to admin_users_path, notice: "已将 #{@user.email} 的角色修改为#{@user.role_label}"
    else
      redirect_to admin_users_path, alert: "无效的角色"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "无权访问管理控制台"
    end
  end
end
