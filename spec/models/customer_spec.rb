require "rails_helper"

RSpec.describe Customer, type: :model do
  subject(:customer) { build(:customer) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:birth_date) }
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_presence_of(:cpf) }

    describe "cpf uniqueness scoped to the store" do
      let(:store) { create(:user) }

      before { create(:customer, user: store, cpf: "12345678901") }

      it "rejects the same cpf within the same store" do
        duplicate = build(:customer, user: store, cpf: "12345678901")
        expect(duplicate).not_to be_valid
      end

      it "allows the same cpf for a different store (multi-tenancy)" do
        other_store = create(:user)
        twin = build(:customer, user: other_store, cpf: "12345678901")
        expect(twin).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:sales).dependent(:destroy) }
    it { is_expected.to have_one(:customer_credit).dependent(:destroy) }
  end

  describe "after_create credit balance" do
    it "creates a customer_credit automatically" do
      customer = create(:customer)
      expect(customer.customer_credit).to be_present
    end

    it "starts the balance at zero" do
      customer = create(:customer)
      expect(customer.customer_credit.available_credits).to eq(0)
    end
  end

  describe "cascading destroy" do
    it "removes the credit balance and the sales" do
      customer = create(:customer)
      create(:sale, user: customer.user, customer: customer)

      expect { customer.destroy }
        .to change(CustomerCredit, :count).by(-1)
        .and change(Sale, :count).by(-1)
    end
  end
end
