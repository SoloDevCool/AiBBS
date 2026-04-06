class FriendLink < ApplicationRecord
  validates :name, presence: true
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的 URL 地址" }

  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(sort_order: :asc, id: :desc) }
end
