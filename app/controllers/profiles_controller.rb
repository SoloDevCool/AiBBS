class ProfilesController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!

  def show
    @tab = params[:tab].presence || "topics"
    @tab = "topics" unless %w[topics following followers blocked].include?(@tab)

    case @tab
    when "following"
      @pagy, @users = pagy(:offset, current_user.following.order(:created_at), limit: 20)
    when "followers"
      @pagy, @users = pagy(:offset, current_user.followers.order(:created_at), limit: 20)
    when "blocked"
      @pagy, @users = pagy(:offset, current_user.blocked_users.order("blocks.created_at"), limit: 20)
    else
      @pagy, @topics = pagy(:offset, current_user.topics.recent, limit: 10)
    end
  end

  def update
    case params[:section]
    when "avatar"
      if params[:user][:avatar].present?
        file = params[:user][:avatar]
        base64 = Base64.strict_encode64(file.read)
        data_uri = "data:#{file.content_type};base64,#{base64}"
        current_user.update!(avatar_data: data_uri)
        redirect_to profile_path, notice: "头像更新成功"
      else
        redirect_to profile_path, alert: "请选择头像文件"
      end
    when "username"
      if current_user.update(username_params)
        redirect_to profile_path, notice: "用户名修改成功"
      else
        @username_error = true
        render :show, status: :unprocessable_entity
      end
    when "password"
      if current_user.update_with_password(password_params)
        bypass_sign_in(current_user)
        redirect_to profile_path, notice: "密码修改成功"
      else
        @password_error = true
        render :show, status: :unprocessable_entity
      end
    when "privacy"
      current_user.update!(profile_public: params[:user][:profile_public] == "1")
      redirect_to profile_path, notice: "隐私设置已更新"
    else
      redirect_to profile_path
    end
  end

  private

  def username_params
    params.require(:user).permit(:username)
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation, :profile_public)
  end
end
