class Tip < ApplicationRecord
  belongs_to :topic
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"
  belongs_to :comment

  DEFAULT_AMOUNTS = [10, 20, 30, 50, 100].freeze

  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true, inclusion: { in: DEFAULT_AMOUNTS } }
  validate :cannot_tip_self
  validate :must_be_topic_author
  validate :sufficient_points

  after_create :transfer_points

  scope :total_for_comment, ->(comment_id) { where(comment_id: comment_id).sum(:amount) }

  def self.total_amount_for(comment)
    where(comment: comment).sum(:amount)
  end

  private

  def cannot_tip_self
    errors.add(:base, "不能给自己打赏") if from_user_id == to_user_id
  end

  def must_be_topic_author
    errors.add(:base, "只有主题发布者可以打赏") if topic.user_id != from_user_id
  end

  def sufficient_points
    if from_user.points < amount
      errors.add(:base, "酷能量不足")
    end
  end

  def transfer_points
    from_user.decrement!(:points, amount)
    to_user.increment!(:points, amount)
  end
end
