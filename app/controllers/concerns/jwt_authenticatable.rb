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
    @current_user
  end

  def current_collaborator
    @current_collaborator
  end

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    payload = JwtAuthenticatable.decode(token)

    unless payload
      render json: { error: "Token inválido ou ausente" }, status: :unauthorized
      return
    end

    if payload[:collaborator_id]
      @current_collaborator = Collaborator.active.find_by(id: payload[:collaborator_id])
      unless @current_collaborator
        render json: { error: "Colaborador inativo ou não encontrado" }, status: :unauthorized
        return
      end
      @current_user = @current_collaborator.user
    else
      @current_user = User.find_by(id: payload[:user_id])
      unless @current_user
        render json: { error: "Token inválido ou ausente" }, status: :unauthorized
      end
    end
  end

  def admin_only!
    return unless current_collaborator
    render json: { error: "Acesso restrito ao administrador" }, status: :forbidden
  end

  def require_permission!(permission)
    return unless current_collaborator
    return if current_collaborator.can?(permission)
    render json: { error: "Sem permissão para esta ação" }, status: :forbidden
  end
end
