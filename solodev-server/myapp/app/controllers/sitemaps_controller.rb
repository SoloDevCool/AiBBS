class SitemapsController < ApplicationController
  def index
    @topics = Topic.includes(:user, :node).order(updated_at: :desc).limit(1000)

    respond_to do |format|
      format.xml
    end
  end
end
