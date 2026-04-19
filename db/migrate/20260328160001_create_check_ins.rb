class CreateCheckIns < ActiveRecord::Migration[7.1]
  def change
    create_table :check_ins do |t|
      t.references :user, null: false, foreign_key: true
      t.date :checked_on, null: false
      t.integer :points_earned, default: 10, null: false

      t.timestamps
    end

    add_index :check_ins, [:user_id, :checked_on], unique: true
  end
end
