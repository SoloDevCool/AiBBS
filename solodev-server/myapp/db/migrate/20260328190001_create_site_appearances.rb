class CreateSiteAppearances < ActiveRecord::Migration[7.1]
  def change
    create_table :site_appearances do |t|
      t.timestamps
    end
  end
end
