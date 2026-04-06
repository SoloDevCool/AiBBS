class InvitationCode < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :users, dependent: :nullify

  validates :code, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 4, maximum: 32 }
  validates :max_uses, numericality: { greater_than: 0, allow_nil: true }

  scope :enabled, -> { where(enabled: true) }
  scope :active, -> { enabled.where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.generate_code(length: 8)
    loop do
      code = SecureRandom.alphanumeric(length).upcase
      return code unless exists?(code: code)
    end
  end

  def self.requirement_enabled?
    SiteSetting.get("invitation_code_enabled", default: "false") == "true"
  end

  def usable?
    enabled? && !expired? && (max_uses.nil? || used_count < max_uses)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def use!
    increment!(:used_count)
  end

  def remaining_uses
    return nil if max_uses.nil? # unlimited
    [max_uses - used_count, 0].max
  end
end
