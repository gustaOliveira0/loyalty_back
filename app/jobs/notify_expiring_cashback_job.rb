class NotifyExpiringCashbackJob < ApplicationJob
  queue_as :default

  # Avisa clientes com cashback vencendo nos próximos N dias (default 3).
  # Agrega por cliente para enviar uma mensagem só com a soma do que está
  # vencendo na janela.
  def perform(days: 3)
    Customer.joins(:cashback_transactions)
            .where(whatsapp_opt_in: true)
            .merge(CashbackTransaction.expiring_within(days))
            .distinct
            .find_each do |customer|
      due = customer.cashback_transactions.expiring_within(days)
      next if due.empty?

      total = due.sum(:amount)
      nearest = due.minimum(:expires_at)
      store = customer.user

      # Dedup: 1 aviso por cliente por dia
      already_sent_today = customer.message_deliveries
        .where(template: "cashback_expiring", status: "sent")
        .where("sent_at >= ?", Time.current.beginning_of_day).exists?
      next if already_sent_today

      SendWhatsappMessageJob.perform_later(
        customer.id,
        "cashback_expiring",
        { amount: CashbackService.format_amount(total, store.cashback_kind),
          expires_at: nearest }
      )
    end
  end
end
