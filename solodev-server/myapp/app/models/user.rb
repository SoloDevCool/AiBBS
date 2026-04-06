class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:github, :google_oauth2, :gitee]

  has_many :topics, dependent: :nullify
  has_many :comments, dependent: :nullify
  has_many :active_follows, class_name: "Follow", foreign_key: :follower_id, dependent: :destroy, inverse_of: :follower
  has_many :following, through: :active_follows, source: :followed
  has_many :reverse_follows, class_name: "Follow", foreign_key: :followed_id, dependent: :destroy, inverse_of: :follower
  has_many :followers, through: :reverse_follows, source: :follower
  has_many :node_follows, dependent: :destroy
  has_many :followed_nodes, through: :node_follows, source: :node
  has_many :check_ins, dependent: :destroy
  has_many :cools, dependent: :destroy
  has_many :active_blocks, class_name: "Block", foreign_key: :blocker_id, dependent: :destroy, inverse_of: :blocker
  has_many :blocked_users, through: :active_blocks, source: :blocked
  has_many :reverse_blocks, class_name: "Block", foreign_key: :blocked_id, dependent: :destroy, inverse_of: :blocked
  has_many :blockers, through: :reverse_blocks, source: :blocker
  has_many :notifications, dependent: :destroy
  belongs_to :invitation_code, optional: true

  enum :role, { user: "user", admin: "admin" }, default: "user"
  scope :real_users, -> { where(is_operational: false) }
  scope :operational, -> { where(is_operational: true) }

  validates :username,
    presence: true,
    length: { minimum: 2, maximum: 20 },
    format: { with: /\A[a-zA-Z0-9_\u4e00-\u9fa5]+\z/, message: "只能包含字母、数字、下划线和中文" },
    uniqueness: { case_sensitive: false },
    allow_nil: true

  def role_label
    case role
    when "admin" then "管理员"
    else "普通用户"
    end
  end

  def display_name
    username.presence || email.split("@").first
  end

  def avatar_data_url
    avatar_data.present? ? avatar_data : nil
  end

  def has_avatar?
    avatar_data.present?
  end

  def followed_by?(user)
    return false if user.nil?
    reverse_follows.exists?(follower_id: user.id)
  end

  def blocked_by?(user)
    return false if user.nil?
    reverse_blocks.exists?(blocker_id: user.id)
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid.to_s).first
  end

  def self.build_from_omniauth(auth)
    placeholder_domain = auth.provider == "google_oauth2" ? "google" : auth.provider
    user = new(
      provider: auth.provider,
      uid: auth.uid.to_s,
      email: auth.info.email || "#{auth.uid}@#{placeholder_domain}.placeholder",
      password: Devise.friendly_token[0, 20]
    )
    user
  end

  def blocked?(user)
    return false if user.nil?
    active_blocks.exists?(blocked_id: user.id)
  end
end
