class CoolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic

  def create
    cool = @topic.cools.build(user: current_user)
    if cool.save
      Notification.notify!(user: @topic.user, actor: current_user, notifiable: @topic, notify_type: :topic_cool)
      render json: { cools_count: @topic.reload.cools_count, action: "cooled" }
    else
      render json: { error: cool.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    cool = @topic.cools.find_by(user: current_user)
    if cool&.destroy
      render json: { cools_count: @topic.reload.cools_count, action: "uncooled" }
    else
      render json: { error: "未点赞" }, status: :unprocessable_entity
    end
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end
end
