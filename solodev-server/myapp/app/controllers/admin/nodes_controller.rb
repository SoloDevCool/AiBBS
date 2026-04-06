class Admin::NodesController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_node, only: [ :edit, :update, :destroy ]

  def index
    @system_nodes = Node.system_ordered
    @interest_nodes = Node.interest_ordered
  end

  def new
    @node = Node.new
  end

  def create
    @node = Node.new(node_params)
    if @node.save
      redirect_to admin_nodes_path, notice: "节点「#{@node.name}」创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @node.update(node_params)
      redirect_to admin_nodes_path, notice: "节点「#{@node.name}」更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @node.destroy
      redirect_to admin_nodes_path, notice: "节点「#{@node.name}」已删除"
    else
      redirect_to admin_nodes_path, alert: "删除失败"
    end
  end

  def reorder
    params[:node_ids].each_with_index do |id, index|
      Node.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def set_node
    @node = Node.find_by!(slug: params[:id])
  end

  def node_params
    params.require(:node).permit(:name, :slug, :icon, :description, :kind, :position)
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "无权访问管理控制台"
    end
  end
end
