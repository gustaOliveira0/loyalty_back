class ExpireCashbackJob < ApplicationJob
  queue_as :default

  def perform
    CashbackService.expire_due!
  end
end
