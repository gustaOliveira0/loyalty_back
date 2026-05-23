require "rails_helper"

RSpec.describe "Api::V1::Sales", type: :request do
  let(:store)       { create(:user) }
  let(:other_store) { create(:user) }
  let(:headers)     { auth_headers(store) }
  let(:customer)    { create(:customer, user: store) }

  describe "POST /api/v1/sales" do
    before { create(:credit_rule, user: store, spend_amount: 100, credit_amount: 10) }

    it "creates a sale and applies credits to the customer" do
      expect {
        post "/api/v1/sales",
             params: { customer_id: customer.id, total: 250 },
             headers: headers
      }.to change(Sale, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("customer_name" => customer.name, "total" => 250.0)
      expect(customer.customer_credit.reload.available_credits).to eq(20)
    end

    it "defaults sale_date to now when omitted" do
      post "/api/v1/sales", params: { customer_id: customer.id, total: 100 }, headers: headers
      expect(response).to have_http_status(:created)
      expect(json["sale_date"]).to be_present
    end

    it "returns 422 for a non-positive total" do
      post "/api/v1/sales", params: { customer_id: customer.id, total: 0 }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to be_present
    end

    it "returns 404 when the customer belongs to another store" do
      foreign = create(:customer, user: other_store)
      post "/api/v1/sales", params: { customer_id: foreign.id, total: 100 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      post "/api/v1/sales", params: { customer_id: customer.id, total: 100 }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/sales" do
    it "lists only the current store's sales, newest first" do
      older = create(:sale, user: store, customer: customer, sale_date: 2.days.ago)
      newer = create(:sale, user: store, customer: customer, sale_date: 1.hour.ago)
      create(:sale, user: other_store) # must not appear

      get "/api/v1/sales", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.map { |s| s["id"] }).to eq([newer.id, older.id])
    end
  end

  describe "GET /api/v1/sales/:id" do
    it "shows an owned sale" do
      sale = create(:sale, user: store, customer: customer)
      get "/api/v1/sales/#{sale.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(sale.id)
    end

    it "returns 404 for another store's sale" do
      sale = create(:sale, user: other_store)
      get "/api/v1/sales/#{sale.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
