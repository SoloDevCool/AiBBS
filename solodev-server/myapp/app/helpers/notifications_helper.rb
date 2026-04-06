module NotificationsHelper
  def notify_icon(notify_type)
    case notify_type
    when "comment_cool", "topic_cool"
      "bi-snow"
    when "tip"
      "bi-gift"
    when "new_comment"
      "bi-chat-dots"
    when "new_reply"
      "bi-reply"
    when "new_follower"
      "bi-person-plus"
    end
  end

  def notify_icon_color(notify_type)
    case notify_type
    when "comment_cool", "topic_cool"
      "text-primary"
    when "tip"
      "text-warning"
    when "new_comment", "new_reply"
      "text-success"
    when "new_follower"
      "text-info"
    end
  end
end
