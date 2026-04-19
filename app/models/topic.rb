class Topic < ApplicationRecord
  belongs_to :node, counter_cache: true
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :cools, dependent: :destroy
  has_many :tips, dependent: :destroy
  has_many :mentions, dependent: :destroy
  has_one :poll, dependent: :destroy
  belongs_to :last_reply_user, class_name: "User", optional: true

  validates :title, presence: true, length: { minimum: 4, maximum: 120 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :node, presence: true
  validates :source_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "请输入有效的 URL 地址" }, if: :is_repost?

  scope :pinned_first, -> { order(Arel.sql("CASE WHEN pinned THEN 0 ELSE 1 END"), pinned_at: :desc, last_reply_at: :desc, created_at: :desc) }
  scope :pinned, -> { where(pinned: true) }
  scope :recent, -> { order(last_reply_at: :desc, created_at: :desc) }
  scope :hot, -> { order(cools_count: :desc, views_count: :desc, created_at: :desc) }
  scope :for_node, ->(slug) { joins(:node).where(nodes: { slug: slug }) }
  scope :from_followed, ->(user) { where(user_id: user.active_follows.select(:followed_id)) }
  scope :not_blocked_by, ->(user) { where.not(user_id: user.active_blocks.select(:blocked_id)) }
  scope :search_by_keyword, ->(keyword) {
    where("topics.title ILIKE ? OR topics.content ILIKE ?", "%#{sanitize_sql_like(keyword)}%", "%#{sanitize_sql_like(keyword)}%")
  }
  scope :trending, -> {
    left_joins(:comments)
      .where(comments: { created_at: 1.day.ago.. })
      .group("topics.id")
      .select("topics.*, COUNT(comments.id) AS trending_score")
      .order(Arel.sql("COUNT(comments.id) DESC, topics.created_at DESC"))
  }

  after_create :process_mentions

  accepts_nested_attributes_for :poll, allow_destroy: true, reject_if: :reject_poll

  def reject_poll(attributes)
    h = attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : attributes
    opts = h['poll_options_attributes']
    opts.blank? || opts.all? { |_, v| v['title'].blank? }
  end

  def cooled_by?(user)
    return false if user.nil?
    cools.exists?(user_id: user.id)
  end

  def has_poll?
    poll.present?
  end

  def voted_poll_by?(user)
    return false if user.nil?
    poll&.voted_by?(user) || false
  end

  def to_param
    if slug.present?
      "#{id}-#{slug}"
    else
      "#{id}-#{title.parameterize}"
    end
  end

  def generate_slug!
    translated = BaiduTranslateService.translate(title)
    self.slug = if translated
      translated.parameterize[0, 80]
    else
      title.parameterize[0, 80]
    end
    self.slug = "topic-#{id}" if slug.blank?
    update_column(:slug, self.slug)
  end

  private

  def process_mentions
    Mention.parse_mentions("#{title} #{content}", user, topic: self)
  end
end
