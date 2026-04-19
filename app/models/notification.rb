class Notification < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  def default_url_options
    Rails.application.config.action_mailer.default_url_options || { host: "localhost", port: 3000 }
  end

  validates :notify_type, presence: true
  validates :user_id, uniqueness: { scope: [:actor_id, :notify_type, :notifiable_id, :notifiable_type] }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  NOTIFY_TYPES = %w[comment_cool topic_cool tip new_comment new_reply new_follower mention topic_vote].freeze

  def self.notify!(user:, actor:, notifiable:, notify_type:)
    return if user.nil? || actor.nil? || user == actor
    return unless NOTIFY_TYPES.include?(notify_type.to_s)
    return if user.blocked?(actor)

    find_or_create_by(user: user, actor: actor, notifiable: notifiable, notify_type: notify_type.to_s)
  end

  def notification_text
    case notify_type
    when "comment_cool"
      "#{actor.display_name} 觉得你的评论很 Cool"
    when "topic_cool"
      "#{actor.display_name} 觉得你的主题很 Cool"
    when "tip"
      amount = notifiable.is_a?(Tip) ? notifiable.amount : 0
      "#{actor.display_name} 打赏了你 #{amount} 酷能量"
    when "new_comment"
      topic = notifiable.is_a?(Comment) ? notifiable.topic : nil
      title = topic ? "「#{topic.title.truncate(20)}」" : ""
      "#{actor.display_name} 评论了你的主题#{title}"
    when "new_reply"
      "#{actor.display_name} 回复了你的评论"
    when "new_follower"
      "#{actor.display_name} 关注了你"
    when "mention"
      mention = notifiable.is_a?(Mention) ? notifiable : nil
      if mention&.comment
        "#{actor.display_name} 在评论中提到了你"
      elsif mention&.topic
        "#{actor.display_name} 在主题中提到了你"
      end
    when "topic_vote"
      topic = notifiable.is_a?(PollOption) ? notifiable.poll&.topic : nil
      title = topic ? "「#{topic.title.truncate(20)}」" : ""
      "#{actor.display_name} 参与了你的投票#{title}"
    end
  end

  def notification_path
    case notify_type
    when "comment_cool"
      comment = notifiable
      topic = comment&.topic
      topic_path_with_node(topic, anchor: "comment-#{comment.id}") if topic
    when "topic_cool"
      topic_path_with_node(notifiable) if notifiable
    when "tip"
      comment = notifiable.is_a?(Tip) ? notifiable.comment : nil
      topic = comment&.topic
      topic_path_with_node(topic, anchor: "comment-#{comment.id}") if topic
    when "new_comment", "new_reply"
      comment = notifiable
      topic = comment&.topic
      topic_path_with_node(topic, anchor: "comment-#{comment.id}") if topic
    when "new_follower"
      user_path(actor)
    when "mention"
      mention = notifiable.is_a?(Mention) ? notifiable : nil
      if mention&.comment
        topic = mention.comment.topic
        topic_path_with_node(topic, anchor: "comment-#{mention.comment.id}") if topic
      elsif mention&.topic
        topic_path_with_node(mention.topic) if mention.topic
      end
    when "topic_vote"
      poll_option = notifiable.is_a?(PollOption) ? notifiable : nil
      topic = poll_option&.poll&.topic
      topic_path_with_node(topic) if topic
    end
  end

  private

  def topic_path_with_node(topic, **opts)
    return nil unless topic&.node
    slug = topic.slug.presence || topic.title.parameterize.presence || "topic-#{topic.id}"
    node_topic_path(node: topic.node.slug, slug: slug, **opts)
  end

  after_create :increment_unread_count
  after_commit(on: :update) do
    if saved_change_to_read? && read?
      user.decrement!(:unread_notifications_count)
      user.update_column(:unread_notifications_count, 0) if user.unread_notifications_count < 0
    end
  end

  after_destroy do
    if !read?
      user.decrement!(:unread_notifications_count)
      user.update_column(:unread_notifications_count, 0) if user.unread_notifications_count < 0
    end
  end

  private

  def increment_unread_count
    user.increment!(:unread_notifications_count)
  end
end
