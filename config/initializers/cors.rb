# LGPD (Art. 46) / segurança: a API trafega dados pessoais (CPF, telefone, etc.)
# e expõe o header Authorization. Por isso NÃO usamos "*" como origem padrão —
# um wildcard permitiria que qualquer site na web fizesse requisições à API em
# nome do usuário e lesse respostas com dados pessoais.
#
# Defina ALLOWED_ORIGINS (lista separada por vírgula) em produção. Sem ela,
# liberamos apenas a origem do próprio frontend (FRONTEND_URL), com fallback
# para o ambiente local de desenvolvimento.
allowed_origins =
  ENV.fetch("ALLOWED_ORIGINS") { ENV.fetch("FRONTEND_URL", "http://localhost:5173") }
    .split(",")
    .map(&:strip)
    .reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]
  end
end
