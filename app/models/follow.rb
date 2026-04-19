class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  validates :follower_id, uniqueness: { scope: :followed_id, message: "已经关注" }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    errors.add(:followed, "不能关注自己") if follower_id == followed_id
  end
end
