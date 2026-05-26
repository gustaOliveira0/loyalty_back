class CashbackService
  class Error < StandardError; end
  class InsufficientBalance < Error; end
  class BelowMinimum < Error; end
  class NotOptedIn < Error; end

  # Cria uma venda a partir de items[product_id, quantity], calcula o subtotal,
  # snapshota o cashback de cada produto, persiste tudo numa transação e cria
  # as entradas "earn" no livro-razão. Retorna a Sale persistida.
  def self.record_sale(user:, customer:, items:, sale_date: nil, notify: true)
    raise Error, "venda precisa de pelo menos 1 item" if items.blank?

    store_unit = user.cashback_kind
    expires_in_days = user.cashback_expires_in_days
    expires_at = expires_in_days.to_i.positive? ? Time.current + expires_in_days.days : nil

    ActiveRecord::Base.transaction do
      sale = user.sales.new(customer: customer, sale_date: sale_date || Time.current, total: 0)

      total = 0.to_d
      total_cashback = 0.to_d

      items.each do |raw|
        product = user.products.find(raw[:product_id])
        qty = raw[:quantity].to_i
        qty = 1 if qty <= 0
        unit_price = raw[:unit_price].present? ? raw[:unit_price].to_d : product.value.to_d
        per_unit_cashback = product.cashback_for(unit_price)
        line_cashback = per_unit_cashback * qty

        sale.sale_items.build(
          product: product,
          quantity: qty,
          unit_price: unit_price,
          cashback_mode: product.cashback_mode,
          cashback_value: product.cashback_value,
          cashback_earned: line_cashback
        )

        total += unit_price * qty
        total_cashback += line_cashback
      end

      sale.total = total
      sale.save!

      sale.sale_items.each do |item|
        next if item.cashback_earned.to_d.zero?

        customer.cashback_transactions.create!(
          sale: sale,
          sale_item: item,
          kind: "earn",
          unit: store_unit,
          amount: item.cashback_earned,
          expires_at: expires_at,
          description: "Cashback de #{item.product.name} (x#{item.quantity})"
        )
      end

      CustomerCredit.refresh_for!(customer)

      if notify && total_cashback.positive? && customer.whatsapp_opt_in
        SendWhatsappMessageJob.perform_later(
          customer.id,
          "cashback_received",
          { amount: format_amount(total_cashback, store_unit), unit: store_unit, expires_at: expires_at }
        )
      end

      sale
    end
  end

  # Resgata cashback do cliente. Respeita saldo + valor mínimo configurado.
  def self.redeem(customer:, amount:, sale: nil, description: "Resgate de cashback")
    user = customer.user
    amount = amount.to_d
    raise Error, "valor de resgate inválido" if amount <= 0

    if user.cashback_min_redeem.to_d.positive? && amount < user.cashback_min_redeem.to_d
      raise BelowMinimum, "valor mínimo para resgate é #{user.cashback_min_redeem}"
    end

    ActiveRecord::Base.transaction do
      balance = customer.balance
      raise InsufficientBalance, "saldo insuficiente (atual: #{balance})" if amount > balance

      tx = customer.cashback_transactions.create!(
        sale: sale,
        kind: "redeem",
        unit: user.cashback_kind,
        amount: -amount,
        description: description
      )

      CustomerCredit.refresh_for!(customer)
      tx
    end
  end

  # Expira transações "earn" cujo expires_at já passou, criando lançamentos
  # "expire" compensatórios. Idempotente: só expira o que ainda está ativo.
  def self.expire_due!(now: Time.current)
    expired_count = 0
    Customer.find_each do |customer|
      due = customer.cashback_transactions
                    .earned
                    .where("expires_at IS NOT NULL AND expires_at <= ?", now)
                    .where.not(id: customer.cashback_transactions.where(kind: "expire").select(:sale_item_id))

      next if due.empty?

      ActiveRecord::Base.transaction do
        due.find_each do |earn|
          # Já expirou? checa idempotência por (sale_item_id, kind=expire)
          already = customer.cashback_transactions.where(kind: "expire", sale_item_id: earn.sale_item_id).exists?
          next if already

          customer.cashback_transactions.create!(
            sale: earn.sale,
            sale_item: earn.sale_item,
            kind: "expire",
            unit: earn.unit,
            amount: -earn.amount,
            description: "Cashback expirado"
          )
          expired_count += 1
        end
        CustomerCredit.refresh_for!(customer)
      end
    end
    expired_count
  end

  def self.format_amount(amount, unit)
    unit == "money" ? format("R$ %.2f", amount.to_f) : "#{amount.to_i} pts"
  end
end
