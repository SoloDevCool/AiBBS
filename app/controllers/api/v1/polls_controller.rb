class Api::V1::PollsController < Api::V1::BaseController
  before_action :authenticate_user!
  before_action :set_topic, only: [:create, :destroy]

  # POST /api/v1/topics/:topic_id/poll
  def create
    poll = @topic.build_poll
    options = params.dig(:poll, :options)
    if options.blank? || options.size < 2
      return render_business_error("至少需要 2 个投票选项")
    end

    closed = params.dig(:poll, :closed) == true

    if poll.update(closed: closed)
      options.each_with_index do |title, index|
        poll.poll_options.create!(title: title, sort_order: index)
      end

      render_success(
        data: poll_data(poll),
        message: "投票创建成功",
        status: :created
      )
    else
      render_business_error("投票创建失败")
    end
  end

  # DELETE /api/v1/topics/:topic_id/poll
  def destroy
    authorize_poll!

    if @topic.poll&.destroy
      render_success(message: "投票已删除")
    else
      render_business_error("投票不存在")
    end
  end

  # POST /api/v1/polls/:poll_id/vote
  def vote
    poll = Poll.find(params[:poll_id])

    if poll.closed?
      return render_business_error("投票已关闭", code: 10010)
    end

    if poll.topic.user == current_user
      return render_business_error("不能给自己投票", code: 10009)
    end

    poll_option = poll.poll_options.find_by(id: params[:poll_option_id])
    unless poll_option
      return render_not_found("投票选项不存在")
    end

    vote = poll_option.votes.build(user: current_user)
    if vote.save
      Notification.notify!(user: poll.topic.user, actor: current_user, notifiable: poll_option, notify_type: :topic_vote)
      render_success(
        data: { poll: poll_data(poll.reload) },
        message: "投票成功"
      )
    else
      render_business_error(vote.errors.full_messages.join(", "))
    end
  end

  # POST /api/v1/polls/:poll_id/close
  def close
    poll = Poll.find(params[:poll_id])
    authorize_poll!(poll)

    poll.close!
    render_success(message: "投票已关闭")
  end

  # POST /api/v1/polls/:poll_id/open
  def open
    poll = Poll.find(params[:poll_id])
    authorize_poll!(poll)

    poll.open!
    render_success(message: "投票已开启")
  end

  private

  def set_topic
    @topic = Topic.find(params[:topic_id])
  end

  def authorize_poll!(poll = nil)
    poll ||= @topic.poll
    unless poll.topic.user == current_user || current_user.admin?
      render_forbidden
    end
  end

  def poll_data(poll)
    voted_option = poll.voted_option_for(current_user)
    {
      id: poll.id,
      closed: poll.closed,
      options: poll.poll_options.map do |o|
        { id: o.id, title: o.title, votes_count: o.votes_count, percentage: o.vote_percentage, voted: voted_option == o }
      end
    }
  end
end
