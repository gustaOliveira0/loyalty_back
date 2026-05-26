namespace :cashback do
  desc "Expira cashback vencido (rode 1x por dia via cron)"
  task expire: :environment do
    expired = CashbackService.expire_due!
    puts "Expirados: #{expired}"
  end

  desc "Notifica clientes com cashback vencendo nos próximos N dias (NEAR_DAYS, default 3)"
  task notify_expiring: :environment do
    days = (ENV["NEAR_DAYS"] || 3).to_i
    NotifyExpiringCashbackJob.perform_now(days: days)
    puts "Notificações de expiração disparadas (janela #{days} dias)"
  end
end
