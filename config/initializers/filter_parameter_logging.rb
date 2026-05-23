# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
#
# LGPD (Lei 13.709/2018 — Art. 6, VII e Art. 46): dados pessoais NÃO podem ser
# gravados em texto puro nos logs da aplicação. O Rails registra os parâmetros de
# toda requisição; sem estes filtros, CPF, telefone, data de nascimento, nome e
# e-mail dos titulares vazariam para STDOUT/arquivos de log e ferramentas de
# observabilidade. Os nomes são casados parcialmente (ex.: "phone" cobre
# "phone_number"; "name" cobre "store_name"/"customer_name").
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  # Dados pessoais tratados pelo sistema de fidelidade:
  :cpf, :phone, :birth_date, :email, :name
]
