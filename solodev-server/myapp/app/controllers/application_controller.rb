class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def robots
    render "robots", layout: false, content_type: "text/plain"
  end

  private

  def redirect_to_topic(topic, **opts)
    redirect_to url_for(controller: 'topics', action: 'show', node: topic.node.slug, slug: topic.slug), **opts
  end

  def topic_location(topic)
    { controller: 'topics', action: 'show', node: topic.node.slug, slug: topic.slug }
  end
end
