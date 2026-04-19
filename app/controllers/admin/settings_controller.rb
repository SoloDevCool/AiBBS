class Admin::SettingsController < Admin::DashboardController
  def index
    @settings = {
      baidu_translate_appid: SiteSetting.get("baidu_translate_appid", default: ""),
      baidu_translate_key: SiteSetting.get("baidu_translate_key", default: ""),
      github_client_id: SiteSetting.get("github_client_id", default: ""),
      github_client_secret: SiteSetting.get("github_client_secret", default: ""),
      google_client_id: SiteSetting.get("google_client_id", default: ""),
      google_client_secret: SiteSetting.get("google_client_secret", default: ""),
      gitee_client_id: SiteSetting.get("gitee_client_id", default: ""),
      gitee_client_secret: SiteSetting.get("gitee_client_secret", default: ""),
      sendflare_api_token: SiteSetting.get("sendflare_api_token", default: ""),
      sendflare_from_email: SiteSetting.get("sendflare_from_email", default: ""),
      email_verification_enabled: SiteSetting.get("email_verification_enabled", default: "false"),
      invitation_code_enabled: SiteSetting.get("invitation_code_enabled", default: "false"),
      fake_users_count: SiteSetting.get("fake_users_count", default: "0"),
      fake_topics_count: SiteSetting.get("fake_topics_count", default: "0"),
      fake_comments_count: SiteSetting.get("fake_comments_count", default: "0"),
      invitation_code_hint: SiteSetting.get("invitation_code_hint", default: "注册需要邀请码，请向已有用户索取")
    }
  end

  def update
    if request.content_type == "application/json"
      params[:settings].each do |key, value|
        SiteSetting.set(key, value)
      end
      render json: { ok: true }
    else
      params[:settings].each do |key, value|
        SiteSetting.set(key, value)
      end
      redirect_to admin_settings_path, notice: "设置已保存"
    end
  end
end
