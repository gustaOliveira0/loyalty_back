require "rails_helper"

RSpec.describe Sale, type: :model do
  subject(:sale) { build(:sale) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:customer) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:total) }
    it { is_expected.to validate_presence_of(:sale_date) }

    it "rejects a zero total" do
      expect(build(:sale, total: 0)).not_to be_valid
    end

    it "rejects a negative total" do
      expect(build(:sale, total: -10)).not_to be_valid
    end
  end

  # ---------------------------------------------------------------------------
  # Core domain rule: apply_credits (after_create)
  #
  # credits_earned = (total / rule.spend_amount).floor * rule.credit_amount
  # using ONLY the rule with the highest spend_amount. See AGENTS.md.
  # ---------------------------------------------------------------------------
  describe "#apply_credits (after_create)" do
    let(:store) { create(:user) }
    let(:customer) { create(:customer, user: store) }

    def available_credits
      customer.customer_credit.reload.available_credits
    end

    context "when the store has no credit rule" do
      it "earns no credits" do
        expect { create(:sale, user: store, customer: customer, total: 500) }
          .not_to change { available_credits }.from(0)
      end
    end

    context "when the store has a single credit rule" do
      before { create(:credit_rule, user: store, spend_amount: 100, credit_amount: 10) }

      it "credits one block for an exact multiple" do
        create(:sale, user: store, customer: customer, total: 100)
        expect(available_credits).to eq(10)
      end

      it "floors partial blocks (R$250 with a R$100 rule => 2 blocks)" do
        create(:sale, user: store, customer: customer, total: 250)
        expect(available_credits).to eq(20)
      end

      it "earns nothing when the total is below one block" do
        create(:sale, user: store, customer: customer, total: 50)
        expect(available_credits).to eq(0)
      end

      it "accumulates credits across multiple sales" do
        create(:sale, user: store, customer: customer, total: 100)
        create(:sale, user: store, customer: customer, total: 300)
        expect(available_credits).to eq(10 + 30)
      end
    end

    context "when the store has several credit rules" do
      # Documented quirk: only the rule with the highest spend_amount is used.
      before do
        create(:credit_rule, user: store, spend_amount: 50,  credit_amount: 1)
        create(:credit_rule, user: store, spend_amount: 200, credit_amount: 10)
      end

      it "uses only the rule with the highest spend_amount" do
        # Highest rule (200/10): floor(300/200) * 10 = 10
        # Lowest rule  (50/1):   floor(300/50)  * 1  = 6  (NOT used)
        create(:sale, user: store, customer: customer, total: 300)
        expect(available_credits).to eq(10)
      end
    end

    context "when the customer has no credit balance yet" do
      before do
        create(:credit_rule, user: store, spend_amount: 100, credit_amount: 10)
        customer.customer_credit.destroy
        customer.reload
      end

      it "recreates the balance before crediting" do
        create(:sale, user: store, customer: customer, total: 100)
        expect(customer.reload.customer_credit.available_credits).to eq(10)
      end
    end
  end
end
