xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  @topics.each do |topic|
    xml.url do
      xml.loc topic_url(topic, host: request.host_with_port)
      xml.changefreq "weekly"
      xml.priority "0.6"
      xml.lastmod topic.updated_at.iso8601
    end
  end
end
