class CreateInvitationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :invitation_codes do |t|
      t.string :code, null: false
      t.integer :max_uses, default: 1, null: false
      t.integer :used_count, default: 0, null: false
      t.boolean :enabled, default: true, null: false
      t.datetime :expires_at
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :invitation_codes, :code, unique: true

    add_reference :users, :invitation_code, foreign_key: true
  end
end
