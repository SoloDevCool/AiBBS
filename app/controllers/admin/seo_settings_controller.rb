class Admin::SeoSettingsController < Admin::DashboardController
  def index
    @settings = {
      seo_site_name: SiteSetting.get("seo_site_name", default: ""),
      seo_title: SiteSetting.get("seo_title", default: ""),
      seo_description: SiteSetting.get("seo_description", default: ""),
      seo_keywords: SiteSetting.get("seo_keywords", default: ""),
      seo_og_image: SiteSetting.get("seo_og_image", default: ""),
      seo_footer_html: SiteSetting.get("seo_footer_html", default: ""),
      seo_google_verification: SiteSetting.get("seo_google_verification", default: ""),
      seo_bing_verification: SiteSetting.get("seo_bing_verification", default: ""),
      seo_baidu_verification: SiteSetting.get("seo_baidu_verification", default: "")
    }
  end

  def update
    params[:settings].each do |key, value|
      SiteSetting.set(key, value)
    end
    redirect_to admin_seo_settings_path, notice: "SEO 设置已保存"
  end
end
