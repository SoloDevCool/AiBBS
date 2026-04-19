class CommentCoolsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment

  def create
    cool = @comment.comment_cools.build(user: current_user)
    if cool.save
      Notification.notify!(user: @comment.user, actor: current_user, notifiable: @comment, notify_type: :comment_cool)
      render json: { cools_count: @comment.comment_cools.count, action: "cooled", points: current_user.reload.points }
    else
      render json: { error: cool.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def destroy
    cool = @comment.comment_cools.find_by(user: current_user)
    if cool&.destroy
      render json: { cools_count: @comment.comment_cools.count, action: "uncooled", points: current_user.reload.points }
    else
      render json: { error: "未点赞" }, status: :unprocessable_entity
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:comment_id])
  end
end
