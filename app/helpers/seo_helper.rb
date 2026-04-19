module SeoHelper
  def seo_meta_tags(title: nil, description: nil, keywords: nil, image: nil, url: nil, type: nil)
    site_name = SiteSetting.get("seo_site_name", default: "SoloDev.Cool")
    site_title = title || content_for(:title) || SiteSetting.get("seo_title", default: "SoloDev.Cool - 独立开发者社区")
    site_description = description || SiteSetting.get("seo_description", default: "独立开发者社区")
    site_keywords = keywords || SiteSetting.get("seo_keywords", default: "")
    site_image = image || SiteSetting.get("seo_og_image", default: "")
    site_url = url || request.original_url

    og_type = type || "website"

    tag = "".html_safe

    # Basic meta
    tag += tag(:meta, name: "description", content: site_description)
    tag += tag(:meta, name: "keywords", content: site_keywords) if site_keywords.present?
    tag += tag(:meta, name: "author", content: site_name)
    tag += tag(:meta, name: "robots", content: "index, follow")

    # Canonical URL
    tag += tag(:link, rel: "canonical", href: site_url)

    # Open Graph
    tag += tag(:meta, property: "og:type", content: og_type)
    tag += tag(:meta, property: "og:site_name", content: site_name)
    tag += tag(:meta, property: "og:title", content: site_title)
    tag += tag(:meta, property: "og:description", content: site_description)
    tag += tag(:meta, property: "og:url", content: site_url)
    tag += tag(:meta, property: "og:locale", content: "zh_CN")
    if site_image.present?
      tag += tag(:meta, property: "og:image", content: site_image.start_with?("http") ? site_image : "#{request.base_url}#{site_image}")
    end

    # Twitter Card
    tag += tag(:meta, name: "twitter:card", content: site_image.present? ? "summary_large_image" : "summary")
    tag += tag(:meta, name: "twitter:title", content: site_title)
    tag += tag(:meta, name: "twitter:description", content: site_description)
    if site_image.present?
      tag += tag(:meta, name: "twitter:image", content: site_image.start_with?("http") ? site_image : "#{request.base_url}#{site_image}")
    end

    tag
  end

  def json_ld_breadcrumb(items)
    json = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map { |item, i|
        {
          "@type" => "ListItem",
          "position" => i + 1,
          "name" => item[:name],
          "item" => item[:url]
        }
      }
    }
    tag.script(json_ld_tag(json), type: "application/ld+json").html_safe
  end

  def json_ld_website
    site_name = SiteSetting.get("seo_site_name", default: "SoloDev.Cool")
    site_description = SiteSetting.get("seo_description", default: "")
    json = {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => site_name,
      "url" => root_url,
      "description" => site_description
    }
    tag.script(json_ld_tag(json), type: "application/ld+json").html_safe
  end

  def json_ld_article(topic)
    json = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => topic.title,
      "author" => {
        "@type" => "Person",
        "name" => topic.user.display_name
      },
      "datePublished" => topic.created_at.iso8601,
      "dateModified" => topic.updated_at.iso8601,
      "url" => topic_url(topic),
      "mainEntityOfPage" => topic_url(topic)
    }
    if topic.node.present?
      json["articleSection"] = topic.node.name
    end
    tag.script(json_ld_tag(json), type: "application/ld+json").html_safe
  end

  def json_ld_person(user)
    json = {
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => user.display_name,
      "url" => user_url(user)
    }
    tag.script(json_ld_tag(json), type: "application/ld+json").html_safe
  end

  private

  def json_ld_tag(hash)
    raw JSON.pretty_generate(hash)
  end
end
