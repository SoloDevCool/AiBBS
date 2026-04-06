class ImagesController < ApplicationController
  skip_forgery_protection only: [:create]
  before_action :authenticate_user!, only: [:create]

  def create
    @image = Image.new(user: current_user)
    @image.file.attach(params[:file])

    if @image.save
      render json: { url: "/images/#{@image.id}" }
    else
      render json: { error: @image.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: "上传失败：#{e.message}" }, status: :internal_server_error
  end

  def show
    image = Image.find(params[:id])
    if image.file.attached?
      redirect_to rails_blob_path(image.file, only_path: true, disposition: "inline")
    else
      head :not_found
    end
  end
end
