# LGPD (Art. 7, I / Art. 8 / Art. 9) — registro do consentimento do titular.
# Para o auto-cadastro público é preciso provar que o titular consentiu com o
# tratamento dos seus dados pessoais. Guardamos o momento do consentimento, o IP
# de origem e a versão do termo aceito, para fins de prestação de contas
# (accountability, Art. 6, X).
class AddConsentToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_column :customers, :consented_at, :datetime
    add_column :customers, :consent_ip, :string
    add_column :customers, :consent_version, :string
  end
end
