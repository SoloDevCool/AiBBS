class Image < ApplicationRecord
  belongs_to :user
  has_one_attached :file

  validates :file, presence: true

  validate :acceptable_file

  private

  def acceptable_file
    return unless file.attached?

    allowed_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    unless allowed_types.include?(file.content_type)
      errors.add(:file, "仅支持 JPG、PNG、GIF、WebP 格式")
    end

    if file.blob.byte_size > 5.megabytes
      errors.add(:file, "大小不能超过 5MB")
    end
  end
end
