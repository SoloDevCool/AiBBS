class Admin::OperationalAccountsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @collection = User.where(is_operational: true).order(created_at: :desc)
    @pagy, @users = pagy(:offset, @collection, limit: 15)
  end

  def batch_generate
    service = BatchAccountGeneratorService.new(
      count: params[:count],
      email_domain: params[:email_domain],
      password: params[:password],
      role: "user"
    )
    result = service.call
    redirect_to admin_operational_accounts_path, notice: result[:message]
  end

  def export
    @users = User.where(is_operational: true).order(created_at: :desc)

    pkg = Axlsx::Package.new
    wb = pkg.workbook
    ws = wb.add_worksheet("运营账号")

    ws.add_row ["#", "用户名", "邮箱", "密码", "角色", "创建时间"]
    ws.styles.add_style num_fmt: "yyyy-mm-dd hh:mm:ss", alignment: { horizontal: :center }

    @users.each_with_index do |user, idx|
      ws.add_row [idx + 1, user.username, user.email, user.plaintext_password, user.role_label, user.created_at.strftime("%Y-%m-%d %H:%M:%S")]
    end

    ws.column_widths [5, 18, 30, 18, 12, 22]
    ws.rows.each do |row|
      row.cells.each { |cell| cell.style.alignment = { horizontal: :center, vertical: :center } }
    end

    send_data pkg.to_stream.read,
      filename: "运营账号_#{Time.current.strftime('%Y%m%d_%H%M%S')}.xlsx",
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      disposition: "attachment"
  end

  def destroy
    @user = User.where(is_operational: true).find(params[:id])
    @user.destroy
    redirect_to admin_operational_accounts_path, notice: "已删除运营账号 #{@user.email}"
  end

  private

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "无权访问管理控制台"
    end
  end
end
