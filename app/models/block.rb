class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocker_id, uniqueness: { scope: :blocked_id, message: "已经屏蔽" }
  validate :cannot_block_self

  private

  def cannot_block_self
    errors.add(:blocked, "不能屏蔽自己") if blocker_id == blocked_id
  end
end
