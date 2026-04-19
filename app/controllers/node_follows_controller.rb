class NodeFollowsController < ApplicationController
  before_action :authenticate_user!

  def create
    @node = Node.find_by!(slug: params[:node_id])
    current_user.node_follows.create!(node: @node)
    redirect_back fallback_location: topics_path, notice: "已关注 #{@node.name}"
  end

  def destroy
    @node = Node.find_by!(slug: params[:node_id])
    current_user.node_follows.find_by(node: @node)&.destroy
    redirect_back fallback_location: topics_path, notice: "已取消关注 #{@node.name}"
  end
end
