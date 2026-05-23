require "rails_helper"

RSpec.describe "Api::V1::CreditRules", type: :request do
  let(:store)       { create(:user) }
  let(:other_store) { create(:user) }
  let(:headers)     { auth_headers(store) }

  describe "GET /api/v1/credit_rules" do
    it "lists only the store's rules ordered by spend_amount" do
      r2 = create(:credit_rule, user: store, spend_amount: 200, credit_amount: 20)
      r1 = create(:credit_rule, user: store, spend_amount: 50,  credit_amount: 5)
      create(:credit_rule, user: other_store)

      get "/api/v1/credit_rules", headers: headers

      expect(json.map { |r| r["id"] }).to eq([r1.id, r2.id])
    end

    it "requires authentication" do
      get "/api/v1/credit_rules"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/credit_rules" do
    it "creates a rule and returns a human-readable description" do
      expect {
        post "/api/v1/credit_rules", params: { spend_amount: 100, credit_amount: 10 }, headers: headers
      }.to change(CreditRule, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("spend_amount" => 100.0, "credit_amount" => 10)
      expect(json["description"]).to include("10 créditos")
    end

    it "returns 422 for invalid data" do
      post "/api/v1/credit_rules", params: { spend_amount: 0, credit_amount: 10 }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/credit_rules/:id" do
    it "updates an owned rule" do
      rule = create(:credit_rule, user: store, credit_amount: 5)
      put "/api/v1/credit_rules/#{rule.id}", params: { credit_amount: 8 }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(rule.reload.credit_amount).to eq(8)
    end

    it "returns 404 for another store's rule" do
      rule = create(:credit_rule, user: other_store)
      put "/api/v1/credit_rules/#{rule.id}", params: { credit_amount: 8 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/credit_rules/:id" do
    it "removes an owned rule" do
      rule = create(:credit_rule, user: store)
      expect { delete "/api/v1/credit_rules/#{rule.id}", headers: headers }
        .to change(CreditRule, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end
end
