class Poll < ApplicationRecord
  belongs_to :topic
  has_many :poll_options, -> { order(:sort_order, :id) }, dependent: :destroy
  has_many :votes, through: :poll_options
  has_many :voters, through: :votes, source: :user

  accepts_nested_attributes_for :poll_options, allow_destroy: true, reject_if: :reject_option

  validates :poll_options, length: { minimum: 2, message: "至少需要2个投票选项" }, if: -> { poll_options.any? || new_record? }

  scope :open, -> { where(closed: false) }
  scope :closed, -> { where(closed: true) }

  def total_votes
    poll_options.sum(:votes_count)
  end

  def voted_by?(user)
    return false if user.nil?
    voters.exists?(user.id)
  end

  def voted_option_for(user)
    return nil if user.nil?
    poll_options.joins(:votes).where(votes: { user_id: user.id }).first
  end

  def close!
    update!(closed: true, closed_at: Time.current)
  end

  def open!
    update!(closed: false, closed_at: nil)
  end

  private

  def reject_option(attributes)
    attributes['title'].blank?
  end
end
