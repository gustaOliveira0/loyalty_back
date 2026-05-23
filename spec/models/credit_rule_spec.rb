require "rails_helper"

RSpec.describe CreditRule, type: :model do
  subject(:credit_rule) { build(:credit_rule) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:spend_amount) }
    it { is_expected.to validate_presence_of(:credit_amount) }

    it "rejects a non-positive spend_amount" do
      expect(build(:credit_rule, spend_amount: 0)).not_to be_valid
    end

    it "rejects a non-positive credit_amount" do
      expect(build(:credit_rule, credit_amount: 0)).not_to be_valid
    end

    it "rejects a fractional credit_amount" do
      expect(build(:credit_rule, credit_amount: 1.5)).not_to be_valid
    end

    it "accepts a positive integer rule" do
      expect(build(:credit_rule, spend_amount: 50.0, credit_amount: 5)).to be_valid
    end
  end
end
