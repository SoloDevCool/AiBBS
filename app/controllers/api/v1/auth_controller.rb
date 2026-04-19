class Api::V1::AuthController < Api::V1::BaseController
  def send_verification_code
    email = params[:email].to_s.strip
    purpose = params[:purpose].to_s.strip

    if email.blank?
      return render_error(message: "请输入邮箱地址")
    end

    unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      return render_error(message: "邮箱格式不正确")
    end

    context = case purpose
    when "register" then "registration"
    when "reset_password" then "reset_password"
    else "registration"
    end

    if context == "registration" && User.exists?(email: email.downcase)
      return render_business_error("该邮箱已被注册", code: 10005)
    end

    if context == "reset_password" && !User.exists?(email: email.downcase)
      return render_business_error("该邮箱未注册")
    end

    result = EmailVerificationService.generate_and_send(email, context: context)
    if result[:success]
      render_success(message: "验证码已发送")
    else
      render_business_error(result[:message], code: 10012)
    end
  end

  def register
    email = params[:email].to_s.strip
    username = params[:username].to_s.strip
    password = params[:password].to_s
    verification_code = params[:verification_code].to_s.strip
    invitation_code = params[:invitation_code].to_s.strip

    if email.blank? || username.blank? || password.blank?
      return render_error(message: "请填写必要信息")
    end

    # Verify invitation code if required
    if InvitationCode.requirement_enabled?
      if invitation_code.blank?
        return render_business_error("请输入邀请码", code: 10003)
      end

      code_record = InvitationCode.active.find_by(code: invitation_code.upcase)
      unless code_record
        return render_business_error("邀请码无效或已过期", code: 10004)
      end

      unless code_record.usable?
        return render_business_error("邀请码已达到使用上限", code: 10004)
      end
      @valid_invitation_code = code_record
    end

    # Verify email code if enabled
    if EmailVerificationService.enabled?
      if verification_code.blank?
        return render_business_error("请输入验证码", code: 10002)
      end

      result = EmailVerificationService.verify(email, verification_code, context: "registration")
      unless result[:success]
        return render_business_error(result[:message], code: 10002)
      end
    end

    user = User.new(
      email: email.downcase,
      username: username,
      password: password
    )

    if user.save
      if @valid_invitation_code
        @valid_invitation_code.use!
        user.update_column(:invitation_code_id, @valid_invitation_code.id)
      end

      token_payload = { sub: user.id, jti: SecureRandom.uuid }
      token = ApiJwt.encode(token_payload)

      render_success(
        data: {
          token: token,
          user: user_profile(user)
        },
        message: "注册成功",
        status: :created
      )
    else
      errors = user.errors.transform_values { |v| v }
      render_error(message: "注册失败", code: 422, errors: errors, status: :unprocessable_entity)
    end
  end

  def login
    email = params[:email].to_s.strip
    password = params[:password].to_s

    user = User.find_by(email: email.downcase)

    if user && user.valid_password?(password)
      token_payload = { sub: user.id, jti: SecureRandom.uuid }
      token = ApiJwt.encode(token_payload)

      render_success(
        data: {
          token: token,
          user: user_profile(user)
        },
        message: "登录成功"
      )
    else
      render_business_error("邮箱或密码错误", code: 10001)
    end
  end

  def logout
    header = request.headers["Authorization"]
    if header&.start_with?("Bearer ")
      token = header.delete_prefix("Bearer ").strip
      payload = ApiJwt.decode(token)
      if payload
        jti = payload[0]["jti"]
        exp = payload[0]["exp"]
        if jti && exp
          JwtDenylistEntry.deny!(jti, Time.at(exp))
        end
      end
    end

    render_success(message: "已登出")
  end

  def refresh
    header = request.headers["Authorization"]
    unless header&.start_with?("Bearer ")
      return render_unauthorized
    end

    token = header.delete_prefix("Bearer ").strip
    payload = ApiJwt.decode(token)

    unless payload
      return render_unauthorized("Token 无效或已过期")
    end

    old_jti = payload[0]["jti"]
    old_exp = payload[0]["exp"]
    if old_jti && old_exp
      JwtDenylistEntry.deny!(old_jti, Time.at(old_exp))
    end

    user = User.find_by(id: payload[0]["sub"])
    unless user
      return render_unauthorized("用户不存在")
    end

    new_payload = { sub: user.id, jti: SecureRandom.uuid }
    new_token = ApiJwt.encode(new_payload)

    render_success(data: { token: new_token })
  end

  def reset_password
    email = params[:email].to_s.strip
    verification_code = params[:verification_code].to_s.strip
    new_password = params[:new_password].to_s

    if email.blank? || verification_code.blank? || new_password.blank?
      return render_error(message: "请填写必要信息")
    end

    if new_password.length < 6
      return render_error(message: "密码至少需要 6 位")
    end

    if EmailVerificationService.enabled?
      result = EmailVerificationService.verify(email, verification_code, context: "reset_password")
      unless result[:success]
        return render_business_error(result[:message], code: 10002)
      end
    end

    user = User.find_by(email: email.downcase)
    unless user
      return render_business_error("该邮箱未注册")
    end

    user.password = new_password
    user.password_confirmation = new_password
    if user.save
      render_success(message: "密码已重置")
    else
      errors = user.errors.transform_values { |v| v }
      render_error(message: "密码重置失败", code: 422, errors: errors, status: :unprocessable_entity)
    end
  end

  private

  def user_profile(user)
    {
      id: user.id,
      email: user.email,
      username: user.display_name,
      points: user.points,
      role: user.role,
      avatar_url: user.avatar_data_url
    }
  end
end
