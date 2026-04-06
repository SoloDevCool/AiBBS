class Admin::FriendLinksController < Admin::DashboardController
  def index
    @friend_links = FriendLink.ordered
  end

  def create
    @friend_link = FriendLink.new(friend_link_params)
    if @friend_link.save
      redirect_to admin_friend_links_path, notice: "友链创建成功"
    else
      @friend_links = FriendLink.ordered
      flash.now[:alert] = "创建失败：#{@friend_link.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @friend_link = FriendLink.find(params[:id])
    if @friend_link.update(friend_link_params)
      redirect_to admin_friend_links_path, notice: "友链更新成功"
    else
      @friend_links = FriendLink.ordered
      flash.now[:alert] = "更新失败：#{@friend_link.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @friend_link = FriendLink.find(params[:id])
    @friend_link.destroy
    redirect_to admin_friend_links_path, notice: "友链删除成功"
  end

  def settings
    SiteSetting.set("footer_text", params[:footer_text]) if params.key?(:footer_text)
    SiteSetting.set("friend_links_enabled", params[:friend_links_enabled]) if params.key?(:friend_links_enabled)
    redirect_to admin_friend_links_path, notice: "设置保存成功"
  end

  private

  def friend_link_params
    params.require(:friend_link).permit(:name, :url, :description, :logo, :sort_order, :is_active)
  end
end
