class Api::V1::NotificationsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_notification, only: [:read]

  def index
    scope = current_user.notifications.recent
    scope = scope.unread if params[:scope] == "unread"

    notifications = pagy_results(scope.includes(:actor, notifiable: [ :topic, :comment, :user, :poll ]))

    render json: {
      code: 0,
      data: notifications.map { |n| notification_item(n) }
    }
  end

  def unread_count
    render_success(data: { unread_count: current_user.unread_notifications_count })
  end

  def read
    @notification.update!(read: true)
    render_success(message: "已标记为已读")
  end

  def read_all
    current_user.notifications.unread.update_all(read: true)
    current_user.update_column(:unread_notifications_count, 0)
    render_success(message: "已全部标记为已读")
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def notification_item(notification)
    item = {
      id: notification.id,
      notify_type: notification.notify_type,
      read: notification.read?,
      actor: {
        id: notification.actor.id,
        username: notification.actor.display_name,
        avatar_url: notification.actor.avatar_data_url
      },
      created_at: notification.created_at
    }

    case notification.notifiable_type
    when "Comment"
      comment = notification.notifiable
      item[:notifiable] = {
        type: "Comment",
        id: comment.id,
        content: comment.content.truncate(100),
        topic: {
          id: comment.topic.id,
          title: comment.topic.title,
          slug: comment.topic.slug
        }
      }
    when "Topic"
      topic = notification.notifiable
      item[:notifiable] = {
        type: "Topic",
        id: topic.id,
        title: topic.title,
        slug: topic.slug
      }
    when "Tip"
      tip = notification.notifiable
      item[:notifiable] = {
        type: "Tip",
        id: tip.id,
        amount: tip.amount,
        comment: {
          id: tip.comment.id,
          content: tip.comment.content.truncate(100),
          topic: { id: tip.topic.id, title: tip.topic.title, slug: tip.topic.slug }
        }
      }
    when "PollOption"
      poll_option = notification.notifiable
      item[:notifiable] = {
        type: "PollOption",
        id: poll_option.id,
        title: poll_option.title,
        topic: poll_option.poll&.topic ? { id: poll_option.poll.topic.id, title: poll_option.poll.topic.title, slug: poll_option.poll.topic.slug } : nil
      }
    when "User"
      followed = notification.notifiable
      item[:notifiable] = {
        type: "User",
        id: followed.id,
        username: followed.display_name
      }
    when "Mention"
      mention = notification.notifiable
      if mention.comment
        item[:notifiable] = {
          type: "Mention",
          id: mention.id,
          comment: {
            id: mention.comment.id,
            content: mention.comment.content.truncate(100),
            topic: { id: mention.topic.id, title: mention.topic.title, slug: mention.topic.slug }
          }
        }
      elsif mention.topic
        item[:notifiable] = {
          type: "Mention",
          id: mention.id,
          topic: { id: mention.topic.id, title: mention.topic.title, slug: mention.topic.slug }
        }
      end
    end

    item
  end
end
