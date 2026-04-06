class CheckIn < ApplicationRecord
  belongs_to :user

  validates :user, uniqueness: { scope: :checked_on, message: "今日已签到" }

  scope :today, -> { where(checked_on: Date.current) }
  scope :recent, -> { order(created_at: :desc) }

  def self.check_in!(user)
    today_record = find_by(user: user, checked_on: Date.current)
    return { success: false, message: "今日已签到" } if today_record

    points = 10
    record = create!(user: user, checked_on: Date.current, points_earned: points)
    user.increment!(:points, points)

    { success: true, message: "签到成功，获得 #{points} 酷能量", points: record.points_earned }
  end
end
