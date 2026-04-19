class SiteAppearance < ApplicationRecord
  has_one_attached :logo
  has_one_attached :favicon

  validate :acceptable_logo
  validate :acceptable_favicon
  validate :acceptable_logo_display_mode

  ALLOWED_LOGO_TYPES = %w[image/png image/jpeg image/gif image/webp image/svg+xml].freeze
  ALLOWED_FAVICON_TYPES = %w[image/png image/jpeg image/gif image/webp image/svg+xml image/x-icon].freeze
  LOGO_DISPLAY_MODES = %w[text logo icon_logo].freeze

  def self.instance
    first || create!
  end

  private

  def acceptable_logo
    validate_attachment(:logo, ALLOWED_LOGO_TYPES, 2.megabytes, "Logo")
  end

  def acceptable_favicon
    validate_attachment(:favicon, ALLOWED_FAVICON_TYPES, 1.megabyte, "图标")
  end

  def validate_attachment(attachment, allowed_types, max_size, label)
    return unless send(attachment).attached?

    if send(attachment).blob.byte_size > max_size
      errors.add(attachment, "#{label}文件大小不能超过 #{(max_size / 1.megabyte).to_i}MB")
    end

    unless allowed_types.include?(send(attachment).blob.content_type)
      errors.add(attachment, "#{label}格式不支持")
    end
  end

  def acceptable_logo_display_mode
    unless LOGO_DISPLAY_MODES.include?(logo_display_mode)
      errors.add(:logo_display_mode, "不合法的展示方式")
    end
  end
end
