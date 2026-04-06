class Api::V1::CommentsController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:create, :destroy, :toggle_login_only]
  before_action :set_topic

  def index
    comments = @topic.comments.includes(:user, :parent).order(:created_at)
    root_comments = comments.root
    children_by_parent = comments.where.not(parent_id: nil).group_by(&:parent_id)

    root_comments = pagy_results(root_comments)

    render json: {
      code: 0,
      data: root_comments.map { |c| comment_tree(c, children_by_parent) }
    }
  end

  def create
    @comment = @topic.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      if @comment.parent_id.present?
        Notification.notify!(user: @comment.parent.user, actor: current_user, notifiable: @comment, notify_type: :new_reply)
      else
        Notification.notify!(user: @topic.user, actor: current_user, notifiable: @comment, notify_type: :new_comment)
      end

      render_success(
        data: comment_item(@comment),
        message: @comment.parent_id.present? ? "回复成功" : "评论成功",
        status: :created
      )
    else
      errors = @comment.errors.transform_values { |v| v }
      render_error(message: "评论失败", code: 422, errors: errors, status: :unprocessable_entity)
    end
  end

  def destroy
    comment = @topic.comments.find(params[:id])

    unless comment.user == current_user || current_user.admin?
      return render_forbidden
    end

    comment.destroy
    render_success(message: "已删除")
  end

  def toggle_login_only
    comment = @topic.comments.find(params[:id])

    unless comment.user == current_user
      return render_forbidden
    end

    comment.update!(login_only: !comment.login_only)
    render_success(data: { id: comment.id, login_only: comment.login_only })
  end

  private

  def set_topic
    @topic = Topic.find_by!(id: params[:topic_id])
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id, :login_only)
  end

  def comment_tree(comment, children_map)
    children = (children_map[comment.id] || []).sort_by(&:created_at)
    {
      id: comment.id,
      content: comment.login_only && !current_user ? "（仅登录可见）" : comment.content,
      author: user_brief(comment.user),
      cools_count: comment.comment_cools.size,
      is_cooled: current_user && comment.comment_cools.exists?(user_id: current_user.id),
      is_author: current_user && comment.user == current_user,
      login_only: comment.login_only,
      tips_total: Tip.total_amount_for(comment),
      created_at: comment.created_at,
      replies: children.map { |c| comment_tree(c, children_map) }
    }
  end

  def comment_item(comment)
    {
      id: comment.id,
      content: comment.content,
      author: user_brief(comment.user),
      cools_count: 0,
      is_cooled: false,
      is_author: true,
      login_only: comment.login_only,
      tips_total: 0,
      created_at: comment.created_at,
      replies: []
    }
  end

  def user_brief(user)
    {
      id: user.id,
      username: user.display_name,
      avatar_url: user.avatar_data_url
    }
  end
end
