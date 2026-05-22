module JwtAuthenticatable
  extend ActiveSupport::Concern

  SECRET = ENV.fetch("JWT_SECRET", "fallback_secret_change_in_production")

  def self.encode(payload)
    payload[:exp] = 30.days.from_now.to_i
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: "HS256")
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::DecodeError
    nil
  end

  included do
    before_action :authenticate_user!
  end

  def current_user
    @current_user ||= begin
      token = request.headers["Authorization"]&.split(" ")&.last
      payload = JwtAuthenticatable.decode(token)
      User.find(payload[:user_id]) if payload
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

  def authenticate_user!
    render json: { error: "Token inválido ou ausente" }, status: :unauthorized unless current_user
  end
end
