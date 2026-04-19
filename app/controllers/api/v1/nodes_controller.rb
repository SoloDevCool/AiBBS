class Api::V1::NodesController < Api::V1::BaseController
  before_action :authenticate_user!, only: [:follow, :unfollow]

  def index
    nodes = Node.ordered
    nodes = nodes.where(kind: params[:kind]) if params[:kind].in?(%w[system interest])

    render json: {
      code: 0,
      data: nodes.map { |n| node_item(n) }
    }
  end

  def follow
    node = Node.find(params[:id])
    current_user.node_follows.create!(node: node)
    render_success(message: "已关注")
  end

  def unfollow
    node = Node.find(params[:id])
    current_user.node_follows.find_by(node: node)&.destroy
    render_success(message: "已取消关注")
  end

  private

  def node_item(node)
    {
      id: node.id,
      name: node.name,
      slug: node.slug,
      kind: node.kind,
      topics_count: node.topics_count,
      is_followed: current_user ? node.followed_by?(current_user) : false,
      position: node.position
    }
  end
end
