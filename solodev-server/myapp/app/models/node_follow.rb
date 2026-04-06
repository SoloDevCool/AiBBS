class NodeFollow < ApplicationRecord
  belongs_to :user
  belongs_to :node

  validates :user_id, uniqueness: { scope: :node_id, message: "已经关注" }
end
