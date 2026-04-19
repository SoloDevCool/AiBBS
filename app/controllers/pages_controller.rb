class PagesController < ApplicationController
  def home
    @nodes = Node.system_ordered + Node.interest_ordered
    @recent_topics = Topic.recent.limit(10)
    @hot_topics = Topic.reorder(views_count: :desc).limit(5)
    @topic_count = Topic.count
    @user_count = User.count
    @node_count = Node.count
    @community_stats = community_stats
    if user_signed_in?
      @followed_nodes = current_user.followed_nodes.left_joins(:node_follows)
        .select("nodes.*, COUNT(node_follows.id) AS followers_count")
        .group("nodes.id")
        .order("followers_count DESC")
        .limit(8)
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
