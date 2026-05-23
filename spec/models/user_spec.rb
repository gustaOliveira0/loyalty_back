require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it "is valid with a well-formed email" do
      expect(build(:user, email: "owner@store.com")).to be_valid
    end

    it "is invalid with a malformed email" do
      expect(build(:user, email: "not-an-email")).not_to be_valid
    end

    describe "email uniqueness" do
      before { create(:user, email: "taken@store.com") }

      it "rejects a duplicate email" do
        expect(build(:user, email: "taken@store.com")).not_to be_valid
      end

      it "rejects a duplicate email regardless of case" do
        expect(build(:user, email: "TAKEN@store.com")).not_to be_valid
      end
    end
  end

  describe "secure password" do
    it { is_expected.to have_secure_password }

    it "authenticates with the correct password" do
      user = create(:user, password: "s3cret!!", password_confirmation: "s3cret!!")
      expect(user.authenticate("s3cret!!")).to eq(user)
    end

    it "does not authenticate with a wrong password" do
      user = create(:user, password: "s3cret!!", password_confirmation: "s3cret!!")
      expect(user.authenticate("wrong")).to be_falsey
    end

    it "stores a bcrypt digest, never the raw password" do
      user = create(:user, password: "plaintext", password_confirmation: "plaintext")
      expect(user.password_digest).not_to eq("plaintext")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:customers).dependent(:destroy) }
    it { is_expected.to have_many(:sales).dependent(:destroy) }
    it { is_expected.to have_many(:credit_rules).dependent(:destroy) }
    it { is_expected.to have_many(:categories).dependent(:destroy) }
    it { is_expected.to have_many(:products).dependent(:destroy) }
  end

  describe "cascading destroy" do
    it "removes everything that belongs to the store" do
      user = create(:user)
      create(:customer, user: user)
      create(:category, user: user)
      create(:credit_rule, user: user)

      expect { user.destroy }
        .to change(Customer, :count).by(-1)
        .and change(Category, :count).by(-1)
        .and change(CreditRule, :count).by(-1)
    end
  end
end
