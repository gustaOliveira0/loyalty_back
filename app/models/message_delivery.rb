class MessageDelivery < ApplicationRecord
  belongs_to :customer

  STATUSES = %w[queued sent failed skipped].freeze

  validates :channel,  presence: true
  validates :template, presence: true
  validates :status,   inclusion: { in: STATUSES }
end
