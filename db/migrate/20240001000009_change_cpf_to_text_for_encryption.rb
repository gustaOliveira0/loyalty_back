# LGPD (Art. 46) — o CPF passa a ser criptografado em repouso (ver Customer).
# O texto cifrado (envelope do Active Record Encryption) é bem maior que os 11
# dígitos originais, então ampliamos a coluna de :string (varchar) para :text.
# O índice composto único (user_id, cpf) continua válido com criptografia
# determinística.
class ChangeCpfToTextForEncryption < ActiveRecord::Migration[7.1]
  def up
    change_column :customers, :cpf, :text
  end

  def down
    change_column :customers, :cpf, :string
  end
end
