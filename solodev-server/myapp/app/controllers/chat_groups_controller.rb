class ChatGroupsController < ApplicationController
  before_action :check_feature_enabled!

  def index
    @categories = ChatGroup::CATEGORIES
    @selected_category = params[:category]
    @chat_groups = ChatGroup.active.sorted
    @chat_groups = @chat_groups.by_category(@selected_category) if @selected_category.present?
    @chat_groups = @chat_groups.group_by(&:category)
  end

  private

  def check_feature_enabled!
    unless SiteSetting.get("chat_groups_enabled", default: "false") == "true"
      redirect_to root_path, alert: "交流群功能未开启"
    end
  end
end
