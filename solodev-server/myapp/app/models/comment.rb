class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :tips, dependent: :destroy
  has_many :comment_cools, dependent: :destroy
  has_many :mentions, dependent: :destroy

  validates :content, presence: true, length: { minimum: 2, maximum: 2000 }

  scope :root, -> { where(parent_id: nil) }
  scope :visible_to, ->(user) { user ? all : where(login_only: false) }

  after_create :update_topic_last_reply, :process_mentions

  def reply_target_name
    parent&.user&.display_name
  end

  private

  def update_topic_last_reply
    topic.update_columns(last_reply_at: created_at, last_reply_user_id: user_id)
  end

  def process_mentions
    Mention.parse_mentions(content, user, topic: topic, comment: self)
  end
end
