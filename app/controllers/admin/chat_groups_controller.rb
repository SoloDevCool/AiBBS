class Admin::ChatGroupsController < Admin::DashboardController
  before_action :set_chat_group, only: [:edit, :update, :destroy]

  def index
    @chat_groups = ChatGroup.order(sort_order: :asc, id: :desc)
  end

  def new
    @chat_group = ChatGroup.new
  end

  def create
    @chat_group = ChatGroup.new(chat_group_params)
    if @chat_group.save
      redirect_to admin_chat_groups_path, notice: "交流群「#{@chat_group.name}」创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if params[:chat_group][:remove_logo] == "1"
      @chat_group.logo.purge
    end
    if @chat_group.update(chat_group_params)
      redirect_to admin_chat_groups_path, notice: "交流群「#{@chat_group.name}」更新成功"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chat_group.destroy
    redirect_to admin_chat_groups_path, notice: "交流群「#{@chat_group.name}」已删除"
  end

  private

  def set_chat_group
    @chat_group = ChatGroup.find(params[:id])
  end

  def chat_group_params
    params.require(:chat_group).permit(:name, :category, :members_count, :description, :sort_order, :is_active, :logo, :remove_logo)
  end
end
