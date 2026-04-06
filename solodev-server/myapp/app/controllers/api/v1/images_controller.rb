class Api::V1::ImagesController < Api::V1::BaseController
  before_action :authenticate_user!

  def create
    @image = Image.new(user: current_user)
    @image.file.attach(params[:file])

    if @image.save
      render_success(
        data: { id: @image.id, url: image_url(@image) },
        message: "上传成功"
      )
    else
      render_business_error(@image.errors.full_messages.join(", "))
    end
  rescue => e
    render_error(message: "上传失败：#{e.message}", code: 500, status: :internal_server_error)
  end

  private

  def image_url(image)
    if image.file.attached?
      Rails.application.routes.url_helpers.rails_blob_path(image.file, only_path: true)
    end
  end
end
