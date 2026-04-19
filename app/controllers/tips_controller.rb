class TipsController < ApplicationController
  before_action :authenticate_user!

  def create
    topic = Topic.find(params[:topic_id])
    comment = topic.comments.find(params[:comment_id])
    tip = Tip.new(
      topic: topic,
      comment: comment,
      from_user: current_user,
      to_user: comment.user,
      amount: params[:amount].to_i
    )

    if tip.save
      Notification.notify!(user: comment.user, actor: current_user, notifiable: tip, notify_type: :tip)
      render json: { success: true, message: "打赏成功", points: current_user.reload.points, tip_total: Tip.total_amount_for(comment) }
    else
      render json: { success: false, message: tip.errors.full_messages.first }, status: :unprocessable_entity
    end
  end
end
