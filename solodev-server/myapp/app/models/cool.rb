class Cool < ApplicationRecord
  belongs_to :user
  belongs_to :topic, counter_cache: true

  validates :user_id, uniqueness: { scope: :topic_id }

  after_create :award_points
  after_destroy :deduct_points

  private

  def award_points
    topic.user&.increment!(:points, 10)
  end

  def deduct_points
    topic.user&.decrement!(:points, 10)
  end
end
