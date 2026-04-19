class Admin::InvitationCodesController < Admin::DashboardController
  include Pagy::Method

  def index
    collection = InvitationCode.includes(:created_by).order(created_at: :desc)
    @pagy, @invitation_codes = pagy(:offset, collection, limit: 20)
  end

  def create
    count = (params[:count].presence || 1).to_i.clamp(1, 100)
    max_uses = params[:max_uses].presence&.to_i
    expires_at = params[:expires_at].presence

    codes = []
    count.times do
      codes << InvitationCode.create!(
        code: InvitationCode.generate_code,
        max_uses: max_uses,
        expires_at: expires_at,
        enabled: true,
        created_by: current_user
      )
    end

    redirect_to admin_invitation_codes_path, notice: "成功生成 #{codes.size} 个邀请码"
  end

  def destroy
    @invitation_code = InvitationCode.find(params[:id])
    @invitation_code.destroy
    redirect_to admin_invitation_codes_path, notice: "邀请码已删除"
  end

  def show
    @invitation_code = InvitationCode.includes(:users).find(params[:id])
  end
end
