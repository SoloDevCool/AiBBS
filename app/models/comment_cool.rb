class CommentCool < ApplicationRecord
  belongs_to :user
  belongs_to :comment

  validates :user_id, uniqueness: { scope: :comment_id }
  validate :cannot_cool_self

  after_create :transfer_points
  after_destroy :revert_points

  private

  def cannot_cool_self
    errors.add(:base, "不能给自己的评论点 cool") if user_id == comment.user_id
  end

  def transfer_points
    user.decrement!(:points, 10)
    comment.user.increment!(:points, 10)
  end

  def revert_points
    user.increment!(:points, 10)
    comment.user.decrement!(:points, 10)
  end
end
