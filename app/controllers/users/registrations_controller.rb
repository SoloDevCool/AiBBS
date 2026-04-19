class Users::RegistrationsController < Devise::RegistrationsController
  # POST /users/send_verification_code
  def send_verification_code
    email = params[:email].to_s.strip

    if email.blank?
      return render json: { success: false, message: "请输入邮箱地址" }, status: :bad_request
    end

    unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      return render json: { success: false, message: "邮箱格式不正确" }, status: :bad_request
    end

    if User.exists?(email: email.downcase)
      return render json: { success: false, message: "该邮箱已被注册" }, status: :unprocessable_content
    end

    result = EmailVerificationService.generate_and_send(email, context: "registration")
    status = result[:success] ? :ok : :unprocessable_content
    render json: { success: result[:success], message: result[:message] }, status: status
  end

  def create
    if InvitationCode.requirement_enabled?
      unless invitation_code_valid?
        return
      end
    end

    if EmailVerificationService.enabled? && !verification_code_valid?
      return
    end
    # Strip verification_code and invitation_code before passing to Devise
    params[:user]&.delete(:verification_code)
    params[:user]&.delete(:invitation_code)
    super

    # After successful registration, mark the invitation code as used
    if resource.persisted? && @valid_invitation_code
      @valid_invitation_code.use!
      resource.update_column(:invitation_code_id, @valid_invitation_code.id)
    end
  end

  private

  def invitation_code_valid?
    code = params.dig(:user, :invitation_code).to_s.strip.upcase

    if code.blank?
      build_resource(sign_up_params_without_code)
      resource.errors.add(:invitation_code, "请输入邀请码")
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
      return false
    end

    invitation_code = InvitationCode.active.find_by(code: code)

    if invitation_code.nil?
      build_resource(sign_up_params_without_code)
      resource.errors.add(:invitation_code, "邀请码无效或已过期")
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
      return false
    end

    unless invitation_code.usable?
      build_resource(sign_up_params_without_code)
      resource.errors.add(:invitation_code, "邀请码已达到使用上限")
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
      return false
    end

    @valid_invitation_code = invitation_code
    true
  end

  def verification_code_valid?
    email = (params.dig(:user, :email) || sign_up_params[:email]).to_s.strip
    code = params.dig(:user, :verification_code).to_s.strip

    if code.blank?
      build_resource(sign_up_params_without_code)
      resource.errors.add(:verification_code, "请输入验证码")
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
      return false
    end

    result = EmailVerificationService.verify(email, code, context: "registration")
    if result[:success]
      true
    else
      build_resource(sign_up_params_without_code)
      resource.errors.add(:verification_code, result[:message])
      respond_with_navigational(resource) { render :new, status: :unprocessable_content }
      false
    end
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :verification_code, :invitation_code)
  end

  def sign_up_params_without_code
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
