class Api::V1::BaseController < ActionController::Base
  include Pagy::Method
  include Pagy::NumericHelperLoader

  skip_forgery_protection
  protect_from_forgery with: :null_session

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid

  private

  def current_user
    @current_user ||= authenticate_token
  end

  def authenticate_user!
    unless current_user
      render_unauthorized("请先登录")
    end
  end

  def authenticate_token
    header = request.headers["Authorization"]
    return nil unless header&.start_with?("Bearer ")

    token = header.delete_prefix("Bearer ").strip
    payload = ApiJwt.decode(token)
    return nil unless payload

    jti = payload[0]["jti"]
    return nil if jti && JwtDenylistEntry.denied?(jti)

    user_id = payload[0]["sub"]
    User.find_by(id: user_id)
  end

  def render_success(data: nil, message: "success", status: :ok)
    json = { code: 0, message: message }
    json[:data] = data if data
    render json: json, status: status
  end

  def render_error(message: "操作失败", code: 400, errors: nil, status: :bad_request)
    json = { code: code, message: message }
    json[:errors] = errors if errors
    render json: json, status: status
  end

  def render_unauthorized(message = "请先登录")
    render_error(message: message, code: 401, status: :unauthorized)
  end

  def render_not_found(message = "资源不存在")
    render_error(message: message, code: 404, status: :not_found)
  end

  def render_forbidden(message = "无权操作")
    render_error(message: message, code: 403, status: :forbidden)
  end

  def render_record_invalid(exception)
    errors = exception.record.errors.transform_values { |v| v }
    render_error(message: "验证失败", code: 422, errors: errors, status: :unprocessable_entity)
  end

  def render_business_error(message, code: 422)
    render_error(message: message, code: code, status: :unprocessable_entity)
  end

  def set_pagy_headers
    return unless @pagy

    response.headers["X-Page"] = @pagy.page.to_s
    response.headers["X-Per-Page"] = @pagy.limit.to_s
    response.headers["X-Total"] = @pagy.count.to_s
    response.headers["X-Total-Pages"] = @pagy.pages.to_s
  end

  def pagy_results(scope, limit: 20)
    per_page = [params[:per_page].to_i, 50].min
    per_page = limit if per_page < 1

    @pagy, records = pagy(:offset, scope, limit: per_page)
    set_pagy_headers
    records
  end
end
