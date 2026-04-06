module ApplicationHelper
  def site_appearance
    @site_appearance ||= SiteAppearance.instance
  end

  def site_logo_url
    site_appearance.logo.attached? ? url_for(site_appearance.logo) : nil
  end

  def site_logo_display_mode
    site_appearance.logo_display_mode.presence || "text"
  end

  def site_favicon_url
    site_appearance.favicon.attached? ? url_for(site_appearance.favicon) : nil
  end

  def highlight_keyword(text, keyword)
    return text if keyword.blank? || text.blank?
    escaped = Regexp.escape(keyword)
    text.gsub(/(#{escaped})/i, '<mark>\1</mark>').html_safe
  end

  def user_link_to(user, **opts)
    return user.display_name unless user
    if user_signed_in? && user == current_user
      link_to user.display_name, profile_path, **opts
    elsif user.profile_public?
      link_to user.display_name, user_path(user), **opts
    else
      user.display_name
    end
  end

  def can_manage_topic?(topic)
    return false unless user_signed_in?
    return true if current_user.admin?
    topic.user == current_user && topic.created_at > 15.minutes.ago
  end

  def user_initial(user)
    user&.display_name&.first&.upcase || 'U'
  end

  def render_mentions(content)
    return content if content.blank?

    rendered = content.gsub(/@([a-zA-Z0-9_\u4e00-\u9fa5]+)/) do |match|
      username = $1
      user = User.find_by(username: username)

      if user && (user_signed_in? ? user == current_user : false) || user&.profile_public?
        link_to "@#{username}", profile_path, class: "mention-link"
      elsif user&.profile_public?
        link_to "@#{username}", user_path(user), class: "mention-link"
      else
        match
      end
    end

    simple_format(rendered).html_safe
  end

  # Override topic_path/topic_url to use /:node/:slug format
  def topic_path(topic_or_id, **options)
    if topic_or_id.is_a?(Topic)
      node = topic_or_id.node&.slug || 'general'
      slug = topic_or_id.slug.presence || topic_or_id.title.parameterize.presence || "topic-#{topic_or_id.id}"
      url_for(controller: 'topics', action: 'show', node: node, slug: slug, only_path: true, **options)
    else
      super
    end
  end

  def topic_url(topic_or_id, **options)
    if topic_or_id.is_a?(Topic)
      node = topic_or_id.node&.slug || 'general'
      slug = topic_or_id.slug.presence || topic_or_id.title.parameterize.presence || "topic-#{topic_or_id.id}"
      url_for(controller: 'topics', action: 'show', node: node, slug: slug, only_path: false, **options)
    else
      super
    end
  end
end
