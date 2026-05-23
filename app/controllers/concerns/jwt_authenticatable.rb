module JwtAuthenticatable
  extend ActiveSupport::Concern

  # LGPD (Art. 46) — o JWT é a chave de acesso a todos os dados pessoais das
  # lojas. Um segredo fixo/conhecido permitiria a qualquer um forjar tokens e
  # acessar dados de qualquer titular. Em produção, JWT_SECRET é obrigatório;
  # fora dela usamos um segredo apenas para desenvolvimento/teste.
  SECRET = ENV.fetch("JWT_SECRET") do
    if Rails.env.production?
      raise "JWT_SECRET deve ser definido em produção (LGPD Art. 46 — proteção de dados pessoais)."
    else
      "insecure_development_only_secret_do_not_use_in_production"
    end
  end

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
