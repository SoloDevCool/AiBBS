class BlocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blocked_user

  def create
    current_user.active_blocks.create!(blocked: @blocked_user)
    redirect_back fallback_location: root_path, notice: "已屏蔽该用户"
  end

  def destroy
    block = current_user.active_blocks.find_by!(blocked: @blocked_user)
    block.destroy!
    redirect_back fallback_location: root_path, notice: "已取消屏蔽"
  end

  private

  def set_blocked_user
    @blocked_user = User.find(params[:id])
  end
end
