class Node < ApplicationRecord
  has_many :topics, dependent: :destroy
  has_many :node_follows, dependent: :destroy
  has_many :followers, through: :node_follows, source: :user

  attribute :kind, default: "interest"
  enum :kind, { system: "system", interest: "interest" }

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_-]+\z/, message: "只能包含小写字母、数字、横线和下划线" }
  validates :icon, length: { maximum: 10 }
  validates :position, presence: true, if: :system?

  # 排序范围
  scope :ordered, -> { order(position: :asc) }
  scope :system_ordered, -> { where(kind: :system).ordered }
  scope :interest_ordered, -> { where(kind: :interest).order(topics_count: :desc) }

  def kind_label
    self.class.kinds_i18n[kind.to_sym]
  end

  def self.kinds_i18n
    { system: "系统节点", interest: "兴趣节点" }
  end

  def to_param
    slug
  end

  def followed_by?(user)
    return false if user.nil?
    node_follows.exists?(user_id: user.id)
  end
end
