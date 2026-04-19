class Vote < ApplicationRecord
  belongs_to :poll_option
  belongs_to :user

  validates :user_id, uniqueness: { scope: :poll_option_id, message: "你已经投过这个选项了" }
  validate :poll_open
  validate :not_own_poll

  after_create :increment_counts
  after_destroy :decrement_counts

  private

  def poll_open
    return if poll_option&.poll&.closed == false
    errors.add(:base, "投票已结束")
  end

  def not_own_poll
    return if poll_option&.poll&.topic&.user_id != user_id
    errors.add(:base, "不能给自己的投票投票")
  end

  def increment_counts
    poll_option.increment!(:votes_count)
  end

  def decrement_counts
    poll_option.decrement!(:votes_count)
  end
end
