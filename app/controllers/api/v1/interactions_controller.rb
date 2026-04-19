class Api::V1::InteractionsController < Api::V1::BaseController
  before_action :authenticate_user!

  # POST /api/v1/topics/:topic_id/cool
  def topic_cool
    topic = Topic.find(params[:topic_id])
    cool = topic.cools.build(user: current_user)

    if cool.save
      Notification.notify!(user: topic.user, actor: current_user, notifiable: topic, notify_type: :topic_cool)
      render_success(data: { cools_count: topic.reload.cools_count }, message: "已点赞")
    else
      render_business_error(cool.errors.full_messages.join(", "))
    end
  end

  # DELETE /api/v1/topics/:topic_id/cool
  def topic_uncool
    topic = Topic.find(params[:topic_id])
    cool = topic.cools.find_by(user: current_user)

    if cool&.destroy
      render_success(data: { cools_count: topic.reload.cools_count }, message: "已取消点赞")
    else
      render_business_error("未点赞")
    end
  end

  # POST /api/v1/comments/:comment_id/cool
  def comment_cool
    comment = Comment.find(params[:comment_id])
    cool = comment.comment_cools.build(user: current_user)

    if cool.save
      Notification.notify!(user: comment.user, actor: current_user, notifiable: comment, notify_type: :comment_cool)
      render_success(data: { cools_count: comment.comment_cools.count, points: current_user.reload.points }, message: "已点赞")
    else
      render_business_error(cool.errors.full_messages.join(", "))
    end
  end

  # DELETE /api/v1/comments/:comment_id/cool
  def comment_uncool
    comment = Comment.find(params[:comment_id])
    cool = comment.comment_cools.find_by(user: current_user)

    if cool&.destroy
      render_success(data: { cools_count: comment.comment_cools.count, points: current_user.reload.points }, message: "已取消点赞")
    else
      render_business_error("未点赞")
    end
  end

  # POST /api/v1/topics/:topic_id/tips
  def tip
    topic = Topic.find(params[:topic_id])
    comment = topic.comments.find_by(id: params[:comment_id])

    unless comment
      return render_not_found("评论不存在")
    end

    tip = Tip.new(
      topic: topic,
      comment: comment,
      from_user: current_user,
      to_user: comment.user,
      amount: params[:amount].to_i
    )

    if tip.save
      Notification.notify!(user: comment.user, actor: current_user, notifiable: tip, notify_type: :tip)
      render_success(
        data: {
          tip: {
            id: tip.id,
            amount: tip.amount,
            from_user: { id: tip.from_user.id, username: tip.from_user.display_name },
            to_user: { id: tip.to_user.id, username: tip.to_user.display_name }
          },
          my_points: current_user.reload.points
        },
        message: "打赏成功"
      )
    else
      render_business_error(tip.errors.full_messages.first)
    end
  end
end
