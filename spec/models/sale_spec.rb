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
  # CashbackService integration — cashback is computed per product, not via
  # credit rules. Sales must go through CashbackService.record_sale.
  # ---------------------------------------------------------------------------
  describe "CashbackService integration" do
    let(:store)    { create(:user) }
    let(:customer) { create(:customer, user: store) }
    let(:category) { create(:category, user: store) }

    def available_credits
      customer.customer_credit.reload.available_credits
    end

    def record_sale(product, qty: 1, unit_price: nil)
      CashbackService.record_sale(
        user: store,
        customer: customer,
        items: [{ product_id: product.id, quantity: qty, unit_price: unit_price || product.value }],
        notify: false
      )
    end

    context "with a percent cashback product" do
      let!(:product) { create(:product, user: store, category: category, value: 100, cashback_mode: "percent", cashback_value: 10) }

      it "credits 10% of the unit price" do
        record_sale(product)
        expect(available_credits).to eq(10)
      end

      it "scales linearly with quantity" do
        record_sale(product, qty: 3)
        expect(available_credits).to eq(30)
      end

      it "accumulates across multiple sales" do
        record_sale(product, qty: 1)
        record_sale(product, qty: 3)
        expect(available_credits).to eq(40)
      end
    end

    context "with a fixed cashback product" do
      let!(:product) { create(:product, user: store, category: category, value: 50, cashback_mode: "fixed", cashback_value: 5) }

      it "credits the fixed amount per unit" do
        record_sale(product, qty: 2)
        expect(available_credits).to eq(10)
      end
    end

    context "with a product earning zero cashback" do
      let!(:product) { create(:product, user: store, category: category, value: 100, cashback_mode: "percent", cashback_value: 0) }

      it "earns no credits" do
        expect { record_sale(product) }.not_to change { available_credits }.from(0)
      end
    end

    context "when the customer credit record was destroyed" do
      let!(:product) { create(:product, user: store, category: category, value: 100, cashback_mode: "fixed", cashback_value: 10) }

      before do
        customer.customer_credit.destroy
        customer.reload
      end

      it "recreates the balance record before crediting" do
        record_sale(product)
        expect(customer.reload.customer_credit.available_credits).to eq(10)
      end
    end
  end
end
