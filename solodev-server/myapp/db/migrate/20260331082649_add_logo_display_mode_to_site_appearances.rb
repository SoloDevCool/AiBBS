class AddLogoDisplayModeToSiteAppearances < ActiveRecord::Migration[8.1]
  def change
    add_column :site_appearances, :logo_display_mode, :string, default: "text", null: false
  end
end
