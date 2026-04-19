class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_topic

  def create
    @comment = @topic.comments.build(comment_params)
    @comment.user = current_user
    if @comment.save
      if parent_comment?
        Notification.notify!(user: @comment.parent.user, actor: current_user, notifiable: @comment, notify_type: :new_reply)
      else
        Notification.notify!(user: @topic.user, actor: current_user, notifiable: @comment, notify_type: :new_comment)
      end
      redirect_to_topic @topic, notice: parent_comment? ? "回复成功" : "评论成功"
    else
      redirect_to_topic @topic, alert: "内容不能为空或过短"
    end
  end

  def destroy
    @comment = @topic.comments.find(params[:id])
    if @comment.user == current_user || current_user.admin?
      @comment.destroy
      redirect_to_topic @topic, notice: "已删除"
    else
      redirect_to_topic @topic, alert: "无权操作"
    end
  end

  def toggle_login_only
    @comment = @topic.comments.find(params[:id])
    if @comment.user == current_user
      @comment.update!(login_only: !@comment.login_only)
      redirect_to_topic @topic, notice: @comment.login_only ? "已设为仅登录可见" : "已取消仅登录可见"
    else
      redirect_to_topic @topic, alert: "无权操作"
    end
  end

  private

  def set_topic
    @topic = Topic.find_by!(id: params[:topic_id])
  end

  def parent_comment?
    params[:comment][:parent_id].present?
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id, :login_only)
  end
end
