class Mention < ApplicationRecord
  belongs_to :topic, optional: true
  belongs_to :comment, optional: true
  belongs_to :user

  validates :user_id, uniqueness: { scope: [:topic_id, :comment_id], message: "已经提及过该用户" }

  scope :for_topic, ->(topic_id) { where(topic_id: topic_id) }
  scope :for_comment, ->(comment_id) { where(comment_id: comment_id) }

  # 解析文本中的@用户名
  def self.parse_mentions(text, actor, topic: nil, comment: nil)
    return unless text

    # 匹配 @username 格式,username可以包含字母、数字、下划线和中文
    usernames = text.scan(/@([a-zA-Z0-9_\u4e00-\u9fa5]+)/).flatten.uniq

    usernames.each do |username|
      user = User.find_by(username: username)
      next unless user
      next if user == actor  # 不@自己
      next if user.blocked?(actor)  # 被屏蔽的不发送

      # 检查是否已经存在mention
      scope = topic ? { topic: topic } : { comment: comment }
      if exists?(**scope, user: user)
        next
      end

      # 创建mention记录
      mention = create!(topic: topic, comment: comment, user: user)

      # 发送通知
      Notification.notify!(
        user: user,
        actor: actor,
        notifiable: mention,
        notify_type: "mention"
      )
    end
  end
end
