class UsersController < ApplicationController
  include Pagy::Method

  def show
    @user = User.find(params[:id])
    unless @user.profile_public? || (user_signed_in? && current_user == @user)
      redirect_to topics_path, alert: "该用户主页未公开"
      return
    end
    @pagy, @topics = pagy(:offset, @user.topics.includes(:node).recent, limit: 15)
  end

  def search
    return head(:forbidden) unless user_signed_in?

    query = params[:q].to_s.strip
    return render json: [] if query.empty?

    users = User.where("username LIKE ?", "#{query}%")
                 .limit(10)
                 .select(:id, :username, :email, :avatar_data)

    results = users.map do |u|
      {
        id: u.id,
        username: u.display_name,
        avatar: u.avatar_data_url
      }
    end

    render json: results
  end
end
