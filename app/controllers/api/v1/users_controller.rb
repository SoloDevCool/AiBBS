class Api::V1::UsersController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:search, :follow, :unfollow, :block, :unblock]

  def show
    user = User.find(params[:id])

    unless user.profile_public? || (current_user && current_user == user)
      return render_forbidden("该用户主页未公开")
    end

    render json: {
      code: 0,
      data: user_public_profile(user)
    }
  end

  def search
    query = params[:q].to_s.strip

    if query.blank?
      return render_success(data: [])
    end

    users = User.where("username LIKE ?", "#{query}%")
                 .limit(10)
                 .select(:id, :username, :avatar_data)

    render_success(
      data: users.map { |u| { id: u.id, username: u.display_name, avatar_url: u.avatar_data_url } }
    )
  end

  def follow
    followed_user = User.find(params[:id])

    follow = current_user.active_follows.create(followed: followed_user)
    if follow.persisted?
      Notification.notify!(user: followed_user, actor: current_user, notifiable: followed_user, notify_type: :new_follower)
      render_success(data: { followers_count: followed_user.reload.followers.count }, message: "已关注")
    else
      render_business_error(follow.errors.full_messages.join(", "))
    end
  end

  def unfollow
    followed_user = User.find(params[:id])
    follow = current_user.active_follows.find_by(followed: followed_user)

    if follow&.destroy
      render_success(data: { followers_count: followed_user.reload.followers.count }, message: "已取消关注")
    else
      render_business_error("未关注该用户")
    end
  end

  def block
    blocked_user = User.find(params[:id])

    block = current_user.active_blocks.create(blocked: blocked_user)
    if block.persisted?
      render_success(message: "已屏蔽")
    else
      render_business_error(block.errors.full_messages.join(", "))
    end
  end

  def unblock
    blocked_user = User.find(params[:id])
    block = current_user.active_blocks.find_by(blocked: blocked_user)

    if block&.destroy
      render_success(message: "已取消屏蔽")
    else
      render_business_error("未屏蔽该用户")
    end
  end

  private

  def user_public_profile(user)
    {
      id: user.id,
      username: user.display_name,
      avatar_url: user.avatar_data_url,
      points: user.points,
      topics_count: user.topics.size,
      comments_count: user.comments.size,
      followers_count: user.followers.count,
      following_count: user.following.count,
      is_followed: current_user ? user.followed_by?(current_user) : false,
      is_blocked: current_user ? current_user.blocked?(user) : false,
      created_at: user.created_at
    }
  end
end
