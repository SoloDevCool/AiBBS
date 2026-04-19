class TopicsController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!, except: [:index, :show, :search]
  before_action :set_topic, only: [:show, :edit, :update, :destroy, :pin, :unpin]
  before_action :set_nodes, only: [:new, :create, :edit, :update]

  def index
    @scope = params[:scope].presence || "recent"
    @scope = "recent" unless %w[recent hot followed trending].include?(@scope)
    @node = Node.find_by(slug: params[:node]) if params[:node]
    @kind = params[:kind].presence if params[:kind].in?(%w[system interest])
    @user_id = params[:user_id].presence
    @all_nodes = Node.system_ordered + Node.interest_ordered
    @hot_nodes = Node.order(topics_count: :desc).limit(10)
    @community_stats = community_stats

    if user_signed_in?
      @sidebar_followed_nodes = current_user.followed_nodes.left_joins(:node_follows)
        .select("nodes.*, COUNT(node_follows.id) AS followers_count")
        .group("nodes.id").order("followers_count DESC").limit(8)
    end

    # 按类型查看节点列表
    if @kind && !@node
      @node_tab = params[:node_tab].presence || "all"
      if @kind == "system"
        @kind_nodes = Node.system_ordered
      else
        @kind_nodes = Node.interest_ordered
      end
      if user_signed_in?
        @followed_nodes = current_user.followed_nodes.where(kind: @kind).order(topics_count: :desc)
        @followed_node_ids = current_user.followed_node_ids
      else
        @followed_nodes = Node.none
        @followed_node_ids = []
      end
      return
    end

    collection = case @scope
    when "hot"
      base_topics.hot
    when "followed"
      if user_signed_in?
        base_topics.from_followed(current_user).recent
      else
        Topic.none
      end
    when "trending"
      base_topics.trending
    else
      base_topics.pinned_first
    end

    collection = collection.not_blocked_by(current_user) if user_signed_in?

    @pagy, @topics = pagy(:offset, collection.includes(:poll, :user, :node, :last_reply_user), limit: 25)
  end

  def show
    @topic.increment!(:views_count)
    @all_nodes = Node.system_ordered + Node.interest_ordered
    @hot_nodes = Node.order(topics_count: :desc).limit(10)
    @community_stats = community_stats
    @comments = @topic.comments.includes(:user, :parent).order(:created_at)
    @poll = @topic.poll
    @poll&.poll_options&.includes(:votes)&.load
    if user_signed_in?
      @sidebar_followed_nodes = current_user.followed_nodes.left_joins(:node_follows)
        .select("nodes.*, COUNT(node_follows.id) AS followers_count")
        .group("nodes.id").order("followers_count DESC").limit(8)
    end
  end

  def new
    @topic = Topic.new
  end

  def create
    @topic = current_user.topics.build(topic_params)
    if @topic.save
      @topic.generate_slug!
      redirect_to_topic @topic, notice: "主题发布成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_topic!
  end

  def update
    authorize_topic!
    if @topic.update(topic_params)
      @topic.generate_slug! if @topic.saved_change_to_title?
      redirect_to_topic @topic, notice: "主题更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_topic!
    if @topic.destroy
      redirect_to topics_path, notice: "主题已删除"
    else
      redirect_to_topic @topic, alert: "删除失败"
    end
  end

  def pin
    unless current_user.admin?
      redirect_to_topic @topic, alert: "无权操作"
      return
    end
    @topic.update!(pinned: true, pinned_at: Time.current)
    redirect_back fallback_location: topic_location(@topic), notice: "已置顶"
  end

  def unpin
    unless current_user.admin?
      redirect_to_topic @topic, alert: "无权操作"
      return
    end
    @topic.update!(pinned: false, pinned_at: nil)
    redirect_back fallback_location: { node: @topic.node.slug, action: 'show', slug: @topic.slug }, notice: "已取消置顶"
  end

  def search
    @q = params[:q].to_s.strip
    if @q.blank?
      redirect_to topics_path, alert: "请输入搜索关键词"
      return
    end
    search_results = Topic.search_by_keyword(@q).includes(:user, :node, :poll).recent
    search_results = search_results.not_blocked_by(current_user) if user_signed_in?
    @pagy, @topics = pagy(:offset, search_results, limit: 25)
    @total_count = search_results.count
  end

  private

  def set_topic
    if params[:slug].present?
      @topic = Topic.find_by(slug: params[:slug])
      @topic ||= Topic.find_by(id: params[/^\d+/])
      raise ActiveRecord::RecordNotFound unless @topic
      if @topic.node&.slug != params[:node]
        redirect_to topic_path(@topic), status: :moved_permanently
      end
    else
      @topic = Topic.find(params[:id])
    end
  end

  def set_nodes
    @nodes = Node.system_ordered + Node.interest_ordered
  end

  def base_topics
    if params[:node]
      Topic.for_node(params[:node])
    elsif params[:kind].in?(%w[system interest])
      Topic.joins(:node).where(nodes: { kind: params[:kind] })
    else
      Topic.all
    end
  end

  def topic_params
    params.require(:topic).permit(:title, :content, :node_id, :is_repost, :source_url,
      poll_attributes: [
        :id, :_destroy,
        poll_options_attributes: [:id, :title, :_destroy]
      ]
    )
  end

  def authorize_topic!
    unless @topic.user == current_user || current_user.admin?
      redirect_to topics_path, alert: "无权操作"
    end
  end

  def community_stats
    fake_users = SiteSetting.get("fake_users_count", default: "0").to_i
    fake_topics = SiteSetting.get("fake_topics_count", default: "0").to_i
    fake_comments = SiteSetting.get("fake_comments_count", default: "0").to_i

    {
      users_count: User.count + fake_users,
      topics_count: Topic.count + fake_topics,
      comments_count: Comment.count + fake_comments
    }
  end
end
