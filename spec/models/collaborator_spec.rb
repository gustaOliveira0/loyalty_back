require "rails_helper"

RSpec.describe Collaborator, type: :model do
  subject(:collaborator) { build(:collaborator) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:birth_date) }
    it { is_expected.to validate_presence_of(:cpf) }
    it { is_expected.to validate_presence_of(:email) }

    it "requires a valid email format" do
      collaborator.email = "not-an-email"
      expect(collaborator).not_to be_valid
      expect(collaborator.errors[:email]).to be_present
    end

    it "enforces unique email across collaborators" do
      create(:collaborator, email: "dup@example.com")
      dup = build(:collaborator, email: "dup@example.com")
      expect(dup).not_to be_valid
    end

    it "enforces unique CPF per user (scope)" do
      user = create(:user)
      create(:collaborator, user: user, cpf: "11111111111")
      dup = build(:collaborator, user: user, cpf: "11111111111")
      expect(dup).not_to be_valid
      expect(dup.errors[:cpf]).to be_present
    end

    it "allows same CPF for different users" do
      create(:collaborator, cpf: "11111111111")
      other_user = create(:user)
      c = build(:collaborator, user: other_user, cpf: "11111111111")
      expect(c).to be_valid
    end

    it "requires a password on creation" do
      c = build(:collaborator, password: nil, password_confirmation: nil)
      expect(c).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "scopes" do
    let!(:active_collab) { create(:collaborator) }
    let!(:inactive_collab) { create(:collaborator, :inactive) }

    it ".active returns only active collaborators" do
      expect(Collaborator.active).to include(active_collab)
      expect(Collaborator.active).not_to include(inactive_collab)
    end
  end

  describe "#authenticate" do
    it "returns the collaborator when password matches" do
      collaborator.save!
      expect(collaborator.authenticate("password123")).to eq(collaborator)
    end

    it "returns false when password does not match" do
      collaborator.save!
      expect(collaborator.authenticate("wrong")).to be_falsy
    end
  end

  describe "#can?" do
    it "returns true for granted permissions" do
      collaborator.can_create_sales = true
      expect(collaborator.can?(:can_create_sales)).to be true
    end

    it "returns false for revoked permissions" do
      collaborator.can_create_sales = false
      expect(collaborator.can?(:can_create_sales)).to be false
    end

    it "returns false for unknown permission names" do
      expect(collaborator.can?(:nonexistent_permission)).to be false
    end
  end

  describe "PERMISSION_FLAGS" do
    it "covers all expected permission columns" do
      expected = %i[
        can_edit_customers can_delete_customers can_create_sales
        can_manage_products can_manage_categories can_manage_credit_rules
        can_view_dashboard can_manage_settings
      ]
      expect(Collaborator::PERMISSION_FLAGS).to match_array(expected)
    end
  end
end
