class Users::PasswordsController < Devise::PasswordsController
  # POST /send_password_reset_code
  def send_verification_code
    email = params[:email].to_s.strip

    if email.blank?
      return render json: { success: false, message: "请输入邮箱地址" }, status: :bad_request
    end

    unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      return render json: { success: false, message: "邮箱格式不正确" }, status: :bad_request
    end

    unless User.exists?(email: email.downcase)
      return render json: { success: false, message: "该邮箱未注册" }, status: :unprocessable_content
    end

    result = EmailVerificationService.generate_and_send(email, context: "reset_password")
    status = result[:success] ? :ok : :unprocessable_content
    render json: { success: result[:success], message: result[:message] }, status: status
  end

  def create
    email = params[:user][:email].to_s.strip
    code = params[:user][:verification_code].to_s.strip

    if EmailVerificationService.enabled?
      if code.blank?
        self.resource = resource_class.new
        resource.errors.add(:verification_code, "请输入验证码")
        respond_with_navigational(resource) { render :new, status: :unprocessable_content }
        return
      end

      result = EmailVerificationService.verify(email, code, context: "reset_password")
      unless result[:success]
        self.resource = resource_class.new
        resource.errors.add(:verification_code, result[:message])
        respond_with_navigational(resource) { render :new, status: :unprocessable_content }
        return
      end
    end

    # Generate token and redirect directly (skip email, already verified)
    user = User.find_by(email: email.downcase)
    if user
      token = user.send(:set_reset_password_token)
      redirect_to edit_user_password_path(reset_password_token: token), notice: "验证成功，请设置新密码"
    else
      self.resource = resource_class.new
      resource.errors.add(:email, "未找到该邮箱对应的账号")
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
    end
  end
end
