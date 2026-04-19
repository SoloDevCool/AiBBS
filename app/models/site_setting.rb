class SiteSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key, default: nil)
    setting = find_by(key: key)
    setting&.value.presence || default
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.value = value
    setting.save!
    setting
  end
end
