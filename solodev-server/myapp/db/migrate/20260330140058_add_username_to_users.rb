class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string

    # 为现有用户设置默认用户名(使用邮箱前缀)
    reversible do |dir|
      dir.up do
        # 先添加唯一索引
        add_index :users, :username, unique: true

        # 为现有用户设置唯一用户名
        User.find_each do |user|
          base_username = user.email.split('@').first
          username = base_username
          counter = 1

          # 确保用户名唯一
          while User.where.not(id: user.id).exists?(username: username)
            username = "#{base_username}#{counter}"
            counter += 1
          end

          user.update_column(:username, username) unless user.username.present?
        end
      end
    end
  end
end
