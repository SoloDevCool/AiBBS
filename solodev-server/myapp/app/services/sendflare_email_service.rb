class SendflareEmailService
  API_BASE_URL = "https://api.sendflare.com"

  def self.send_email(to:, subject:, body:, from: nil)
    new.send_email(to: to, subject: subject, body: body, from: from)
  end

  def send_email(to:, subject:, body:, from: nil)
    api_token = SiteSetting.get("sendflare_api_token")
    from_email = from || SiteSetting.get("sendflare_from_email")

    if api_token.blank? || from_email.blank?
      return { success: false, message: "Sendflare API 未配置，请在管理控制台设置 API Token 和发件邮箱" }
    end

    uri = URI.parse("#{API_BASE_URL}/v1/send")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json; charset=utf-8"
    request["Authorization"] = "Bearer #{api_token}"
    request.body = JSON.dump({
      from: from_email,
      to: to,
      subject: subject,
      body: body
    })

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10) do |http|
      http.request(request)
    end

    parsed = JSON.parse(response.body)

    if parsed["success"] == true
      { success: true, message: "邮件发送成功" }
    else
      { success: false, message: parsed["message"] || "邮件发送失败" }
    end
  rescue JSON::ParserError
    { success: false, message: "邮件服务返回数据异常" }
  rescue Net::OpenTimeout, Net::ReadTimeout
    { success: false, message: "邮件服务连接超时，请稍后重试" }
  rescue StandardError => e
    { success: false, message: "邮件发送失败: #{e.message}" }
  end
end
