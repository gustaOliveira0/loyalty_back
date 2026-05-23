require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  let(:store)       { create(:user) }
  let(:other_store) { create(:user) }
  let(:headers)     { auth_headers(store) }

  describe "GET /api/v1/customers" do
    it "lists only the current store's customers" do
      mine   = create(:customer, user: store)
      _theirs = create(:customer, user: other_store)

      get "/api/v1/customers", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.map { |c| c["id"] }).to contain_exactly(mine.id)
    end

    it "includes the available_credits in each item" do
      create(:customer, user: store)
      get "/api/v1/customers", headers: headers
      expect(json.first).to include("available_credits" => 0)
    end

    it "requires authentication" do
      get "/api/v1/customers"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/customers/:id" do
    it "shows an owned customer" do
      customer = create(:customer, user: store)
      get "/api/v1/customers/#{customer.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(customer.id)
    end

    it "returns 404 for a customer of another store (multi-tenancy)" do
      customer = create(:customer, user: other_store)
      get "/api/v1/customers/#{customer.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/customers" do
    let(:valid_params) do
      { name: "Maria", birth_date: "1990-05-20", phone_number: "11999998888", cpf: "39053344705" }
    end

    it "creates a customer and its zeroed credit balance" do
      expect { post "/api/v1/customers", params: valid_params, headers: headers }
        .to change(Customer, :count).by(1)
        .and change(CustomerCredit, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Maria", "available_credits" => 0)
    end

    it "returns 422 for invalid data" do
      post "/api/v1/customers", params: valid_params.merge(name: ""), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to be_present
    end

    it "returns 422 for a duplicate cpf within the store" do
      create(:customer, user: store, cpf: "39053344705")
      post "/api/v1/customers", params: valid_params, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "allows the same cpf in a different store" do
      create(:customer, user: other_store, cpf: "39053344705")
      expect { post "/api/v1/customers", params: valid_params, headers: headers }
        .to change(Customer, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT /api/v1/customers/:id" do
    it "updates an owned customer" do
      customer = create(:customer, user: store, name: "Antigo")
      put "/api/v1/customers/#{customer.id}", params: { name: "Novo" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(customer.reload.name).to eq("Novo")
    end

    it "returns 404 when updating another store's customer" do
      customer = create(:customer, user: other_store)
      put "/api/v1/customers/#{customer.id}", params: { name: "X" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/customers/:id" do
    it "removes an owned customer (and cascades the credit)" do
      customer = create(:customer, user: store)
      expect { delete "/api/v1/customers/#{customer.id}", headers: headers }
        .to change(Customer, :count).by(-1)
        .and change(CustomerCredit, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 when deleting another store's customer" do
      customer = create(:customer, user: other_store)
      delete "/api/v1/customers/#{customer.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
