class Admin::AppearanceSettingsController < Admin::DashboardController
  def index
    @appearance = SiteAppearance.instance
  end

  def update
    @appearance = SiteAppearance.instance

    if params.dig(:site_appearance, :remove_logo) == "1"
      @appearance.logo.purge_later
    end
    if params.dig(:site_appearance, :remove_favicon) == "1"
      @appearance.favicon.purge_later
    end

    if params[:site_appearance].present?
      @appearance.update(appearance_params)
    end

    redirect_to admin_appearance_settings_path, notice: "外观设置已保存"
  end

  private

  def appearance_params
    params.require(:site_appearance).permit(:logo, :favicon, :logo_display_mode)
  end
end
