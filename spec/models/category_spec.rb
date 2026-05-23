require "rails_helper"

RSpec.describe Category, type: :model do
  subject(:category) { build(:category) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:products).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "cascading destroy" do
    it "removes the products under the category" do
      category = create(:category)
      create(:product, category: category, user: category.user)

      expect { category.destroy }.to change(Product, :count).by(-1)
    end
  end
end
