class PollOption < ApplicationRecord
  belongs_to :poll
  has_many :votes, dependent: :destroy
  has_many :voters, through: :votes, source: :user

  validates :title, presence: true, length: { minimum: 1, maximum: 100 }

  def vote_percentage
    total = poll.total_votes
    return 0 if total.zero?
    (votes_count.to_f / total * 100).round(1)
  end
end
