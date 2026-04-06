class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.text :value
      t.timestamps

      t.index :key, unique: true
    end
  end
end
