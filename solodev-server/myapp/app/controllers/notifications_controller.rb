class NotificationsController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!
  before_action :set_notification, only: [:update]

  def index
    scope = current_user.notifications.recent
    scope = scope.unread if params[:scope] == "unread"
    @pagy, @notifications = pagy(:offset, scope, limit: params[:per_page] || 20)
  end

  def update
    @notification.update!(read: true)
    head :ok
  end

  def read_all
    current_user.notifications.unread.update_all(read: true)
    current_user.update_column(:unread_notifications_count, 0)
    redirect_back fallback_location: notifications_path, notice: "已全部标记为已读"
  end

  def unread_count
    render json: { count: current_user.unread_notifications_count }
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
