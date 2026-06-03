require "rails_helper"

RSpec.describe CustomerCredit, type: :model do
  # Use the credit auto-created by Customer#after_create as the subject,
  # so we never collide with the has_one relationship.
  subject(:customer_credit) { create(:customer).customer_credit }

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:available_credits).is_greater_than_or_equal_to(0) }

    it "is invalid with a negative balance" do
      customer_credit.available_credits = -1
      expect(customer_credit).not_to be_valid
    end

    it "is valid with a zero balance" do
      customer_credit.available_credits = 0
      expect(customer_credit).to be_valid
    end

    it "is valid with a positive balance" do
      customer_credit.available_credits = 50
      expect(customer_credit).to be_valid
    end
  end
end
