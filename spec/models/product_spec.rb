require "rails_helper"

RSpec.describe Product, type: :model do
  subject(:product) { build(:product) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:category) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }

    it "rejects a negative value" do
      expect(build(:product, value: -1)).not_to be_valid
    end

    it "accepts a zero value (free product)" do
      expect(build(:product, value: 0)).to be_valid
    end

    it "allows a blank description" do
      expect(build(:product, description: nil)).to be_valid
    end
  end
end
