class CreateNodes < ActiveRecord::Migration[8.1]
  def change
    create_table :nodes do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :icon
      t.text :description
      t.integer :topics_count, default: 0, null: false

      t.timestamps
    end

    add_index :nodes, :slug, unique: true
  end
end
