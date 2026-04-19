class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def github
    handle_omniauth("GitHub")
  end

  def google_oauth2
    handle_omniauth("Google")
  end

  def gitee
    handle_omniauth("Gitee")
  end

  def failure
    redirect_to root_path, alert: "第三方登录失败"
  end

  # GET /users/oauth_invitation_code
  # 新 OAuth 用户需要输入邀请码的页面
  def oauth_invitation_code
    @oauth_data = session["devise.oauth_pending_data"]
    if @oauth_data.blank?
      redirect_to new_user_session_path, alert: "登录信息已过期，请重新登录"
    end
  end

  # POST /users/verify_oauth_invitation_code
  def verify_oauth_invitation_code
    @oauth_data = session["devise.oauth_pending_data"]
    if @oauth_data.blank?
      redirect_to new_user_session_path, alert: "登录信息已过期，请重新登录"
      return
    end

    code = params[:invitation_code].to_s.strip.upcase
    if code.blank?
      redirect_to users_oauth_invitation_code_path, alert: "请输入邀请码"
      return
    end

    invitation_code = InvitationCode.active.find_by(code: code)
    if invitation_code.nil?
      redirect_to users_oauth_invitation_code_path, alert: "邀请码无效或已过期"
      return
    end

    unless invitation_code.usable?
      redirect_to users_oauth_invitation_code_path, alert: "邀请码已达到使用上限"
      return
    end

    auth = OmniAuth::AuthHash.new(@oauth_data)
    user = User.build_from_omniauth(auth)
    user.save!
    invitation_code.use!
    user.update_column(:invitation_code_id, invitation_code.id)

    session.delete("devise.oauth_pending_data")
    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: auth.provider) if is_navigational_format?
  end

  private

  def handle_omniauth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
    elsif InvitationCode.requirement_enabled?
      # 新用户且需要邀请码：暂存 OAuth 数据，跳转到邀请码验证页
      session["devise.oauth_pending_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to users_oauth_invitation_code_path
    else
      @user = User.build_from_omniauth(request.env["omniauth.auth"])
      if @user.save
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      else
        session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except("extra")
        redirect_to new_user_registration_url, alert: "#{kind} 登录失败，请重试"
      end
    end
  end
end
