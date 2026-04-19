class ChatGroup < ApplicationRecord
  has_one_attached :logo

  validates :name, presence: true, length: { maximum: 100 }
  validates :category, length: { maximum: 50 }
  validates :members_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :description, length: { maximum: 500 }

  scope :active, -> { where(is_active: true) }
  scope :sorted, -> { order(sort_order: :asc, id: :asc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  CATEGORIES = {
    "wechat" => "微信群",
    "qq" => "QQ群",
    "telegram" => "Telegram",
    "discord" => "Discord",
    "yuanbaopai" => "元宝派",
    "other" => "其他"
  }.freeze

  def category_label
    CATEGORIES[category] || category
  end
end
