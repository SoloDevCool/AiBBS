class Api::V1::ProfileController < Api::V1::BaseController
  before_action :authenticate_user!

  def show
    render_success(
      data: {
        user: current_user_profile,
        stats: {
          topics_count: current_user.topics.size,
          comments_count: current_user.comments.size,
          followers_count: current_user.followers.count,
          following_count: current_user.following.count,
          blocks_count: current_user.blocked_users.count
        }
      }
    )
  end

  def update
    if params[:avatar].present?
      file = params[:avatar]
      base64 = Base64.strict_encode64(file.read)
      data_uri = "data:#{file.content_type};base64,#{base64}"
      current_user.update!(avatar_data: data_uri)
      render_success(data: current_user_profile, message: "头像更新成功")
    elsif params[:username].present?
      if current_user.update(username: params[:username])
        render_success(data: current_user_profile, message: "用户名修改成功")
      else
        errors = current_user.errors.transform_values { |v| v }
        render_error(message: "修改失败", code: 422, errors: errors, status: :unprocessable_entity)
      end
    else
      render_error(message: "没有可更新的内容")
    end
  end

  def password
    unless current_user.valid_password?(params[:current_password])
      return render_business_error("当前密码错误")
    end

    if params[:new_password].length < 6
      return render_error(message: "新密码至少需要 6 位")
    end

    if params[:new_password] != params[:new_password_confirmation]
      return render_error(message: "两次输入的密码不一致")
    end

    current_user.update!(password: params[:new_password], password_confirmation: params[:new_password_confirmation])
    render_success(message: "密码已修改")
  end

  private

  def current_user_profile
    {
      id: current_user.id,
      email: current_user.email,
      username: current_user.display_name,
      avatar_url: current_user.avatar_data_url,
      points: current_user.points,
      role: current_user.role,
      profile_public: current_user.profile_public?,
      created_at: current_user.created_at
    }
  end
end
