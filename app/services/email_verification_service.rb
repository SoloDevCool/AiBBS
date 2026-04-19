class EmailVerificationService
  CODE_LENGTH = 6
  CODE_EXPIRY = 5.minutes
  RATE_LIMIT_KEY_PREFIX = "email_verify_rate:"
  RATE_LIMIT_EXPIRY = 60.seconds
  MAX_ATTEMPTS_PER_MINUTE = 1

  def self.generate_and_send(email, context: "registration")
    new.generate_and_send(email, context: context)
  end

  def self.verify(email, code, context: "registration")
    new.verify(email, code, context: context)
  end

  def self.enabled?
    SiteSetting.get("email_verification_enabled", default: "false") == "true"
  end

  def generate_and_send(email, context:)
    # Rate limiting
    rate_key = "#{RATE_LIMIT_KEY_PREFIX}#{context}:#{email.downcase}"
    if Rails.cache.read(rate_key)
      return { success: false, message: "发送过于频繁，请 #{RATE_LIMIT_EXPIRY.in_seconds} 秒后再试" }
    end

    # Generate 6-digit code
    code = CODE_LENGTH.times.map { rand(0..9) }.join

    # Store code in cache
    cache_key = "email_verify_code:#{context}:#{email.downcase}"
    Rails.cache.write(cache_key, code, expires_in: CODE_EXPIRY)

    # Set rate limit
    Rails.cache.write(rate_key, true, expires_in: RATE_LIMIT_EXPIRY)

    # Send email
    subject_map = {
      "registration" => "注册验证码",
      "reset_password" => "密码重置验证码"
    }
    subject = subject_map[context] || "邮箱验证码"

    body = <<~BODY
      您的邮箱验证码是：#{code}

      此验证码在 #{CODE_EXPIRY.in_seconds / 60} 分钟内有效。如果这不是您本人的操作，请忽略此邮件。

      ---
      #{ActionMailer::Base.default_url_options[:host] || 'SoloDev.Cool'}
    BODY

    result = SendflareEmailService.send_email(to: email, subject: subject, body: body)
    if result[:success]
      { success: true, message: "验证码已发送" }
    else
      # Clean up cache on failure
      Rails.cache.delete(cache_key)
      Rails.cache.delete(rate_key)
      result
    end
  end

  def verify(email, code, context:)
    cache_key = "email_verify_code:#{context}:#{email.downcase}"
    cached_code = Rails.cache.read(cache_key)

    if cached_code.nil?
      return { success: false, message: "验证码已过期，请重新获取" }
    end

    if cached_code == code.strip
      Rails.cache.delete(cache_key)
      { success: true, message: "验证成功" }
    else
      { success: false, message: "验证码错误" }
    end
  end
end
