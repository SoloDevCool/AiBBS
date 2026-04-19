class Api::V1::TopicsController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  before_action :set_topic, only: [:show, :update, :destroy]

  def index
    scope = params[:scope].presence || "recent"
    scope = "recent" unless %w[recent hot followed trending].include?(scope)

    base = case scope
    when "hot"
      Topic.hot
    when "followed"
      if current_user
        Topic.from_followed(current_user).recent
      else
        Topic.none
      end
    when "trending"
      Topic.trending
    else
      Topic.pinned_first
    end

    if params[:node_id].present?
      base = base.where(node_id: params[:node_id])
    elsif params[:kind].in?(%w[system interest])
      base = base.joins(:node).where(nodes: { kind: params[:kind] })
    end

    base = base.not_blocked_by(current_user) if current_user

    topics = pagy_results(base.includes(:user, :node, :poll))

    render json: {
      code: 0,
      data: topics.map { |t| topic_list_item(t) }
    }
  end

  def show
    @topic.increment!(:views_count)

    comments = @topic.comments.includes(:user, :parent).order(:created_at)
    root_comments = comments.root
    children_by_parent = comments.where.not(parent_id: nil).group_by(&:parent_id)

    poll = nil
    if @topic.poll
      @topic.poll.poll_options&.load
      poll = poll_data(@topic.poll, current_user)
    end

    render json: {
      code: 0,
      data: {
        id: @topic.id,
        title: @topic.title,
        slug: @topic.slug,
        content: @topic.content,
        node: { id: @topic.node.id, name: @topic.node.name, slug: @topic.node.slug },
        author: user_brief(@topic.user),
        comments_count: @topic.comments.size,
        cools_count: @topic.cools_count,
        views_count: @topic.views_count,
        pinned: @topic.pinned,
        is_repost: @topic.is_repost,
        source_url: @topic.source_url,
        is_cooled: @topic.cooled_by?(current_user),
        is_author: current_user && @topic.user == current_user,
        has_poll: @topic.has_poll?,
        poll: poll,
        comments: root_comments.map { |c| comment_tree(c, children_by_parent, current_user) },
        created_at: @topic.created_at,
        updated_at: @topic.updated_at
      }
    }
  end

  def create
    topic = current_user.topics.build(topic_params)

    if topic.save
      topic.generate_slug!
      render_success(
        data: { id: topic.id, slug: topic.slug, title: topic.title },
        message: "话题创建成功",
        status: :created
      )
    else
      errors = topic.errors.transform_values { |v| v }
      render_error(message: "创建失败", code: 422, errors: errors, status: :unprocessable_entity)
    end
  end

  def update
    authorize_topic!

    if @topic.update(topic_params)
      @topic.generate_slug! if @topic.saved_change_to_title?
      render_success(data: { id: @topic.id, title: @topic.title }, message: "更新成功")
    else
      errors = @topic.errors.transform_values { |v| v }
      render_error(message: "更新失败", code: 422, errors: errors, status: :unprocessable_entity)
    end
  end

  def destroy
    authorize_topic!

    @topic.destroy
    render_success(message: "删除成功")
  end

  def search
    q = params[:q].to_s.strip

    if q.blank?
      return render_error(message: "请输入搜索关键词")
    end

    results = Topic.search_by_keyword(q).includes(:user, :node, :poll).recent
    results = results.not_blocked_by(current_user) if current_user

    topics = pagy_results(results)

    render json: {
      code: 0,
      data: topics.map { |t| topic_list_item(t) }
    }
  end

  private

  def set_topic
    @topic = Topic.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @topic
  end

  def topic_params
    params.require(:topic).permit(:title, :content, :node_id, :is_repost, :source_url)
  end

  def authorize_topic!
    unless @topic.user == current_user || current_user.admin?
      render_forbidden
    end
  end

  def topic_list_item(topic)
    {
      id: topic.id,
      title: topic.title,
      slug: topic.slug,
      excerpt: topic.content.truncate(100),
      node: { id: topic.node.id, name: topic.node.name, slug: topic.node.slug },
      author: user_brief(topic.user),
      comments_count: topic.comments.size,
      cools_count: topic.cools_count,
      views_count: topic.views_count,
      pinned: topic.pinned,
      is_cooled: topic.cooled_by?(current_user),
      has_poll: topic.has_poll?,
      created_at: topic.created_at
    }
  end

  def user_brief(user)
    {
      id: user.id,
      username: user.display_name,
      avatar_url: user.avatar_data_url
    }
  end

  def comment_tree(comment, children_map, current_user)
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
      replies: children.map { |c| comment_tree(c, children_map, current_user) }
    }
  end

  def poll_data(poll, current_user)
    voted_option = current_user ? poll.voted_option_for(current_user) : nil
    {
      id: poll.id,
      closed: poll.closed,
      options: poll.poll_options.map do |o|
        { id: o.id, title: o.title, votes_count: o.votes_count, percentage: o.vote_percentage, voted: voted_option == o }
      end
    }
  end
end
