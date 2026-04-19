module ApiJwt
  SECRET_KEY = Rails.application.credentials.dig(:api_jwt, :secret_key) || ENV.fetch("API_JWT_SECRET_KEY", "solodev_cool_api_jwt_secret_key_change_in_production")

  TOKEN_EXPIRY = 24.hours
  REFRESH_EXPIRY = 30.days

  def self.encode(payload, expiry: TOKEN_EXPIRY)
    payload[:exp] = (Time.current + expiry).to_i
    JWT.encode(payload, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end
end
