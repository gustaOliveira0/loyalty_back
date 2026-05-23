require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  let(:store)       { create(:user) }
  let(:other_store) { create(:user) }
  let(:headers)     { auth_headers(store) }
  let(:category)    { create(:category, user: store) }

  describe "GET /api/v1/products" do
    it "lists only the store's products ordered by name" do
      b = create(:product, user: store, category: category, name: "Banana")
      a = create(:product, user: store, category: category, name: "Abacaxi")
      create(:product, user: other_store)

      get "/api/v1/products", headers: headers

      expect(json.map { |p| p["id"] }).to eq([a.id, b.id])
    end

    it "filters by category_id when provided" do
      other_category = create(:category, user: store)
      wanted = create(:product, user: store, category: category)
      create(:product, user: store, category: other_category)

      get "/api/v1/products", params: { category_id: category.id }, headers: headers

      expect(json.map { |p| p["id"] }).to contain_exactly(wanted.id)
    end

    it "requires authentication" do
      get "/api/v1/products"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/products" do
    it "creates a product under a category and returns numeric value" do
      params = { category_id: category.id, name: "Coca-Cola", value: 7.5, description: "Lata" }
      expect { post "/api/v1/products", params: params, headers: headers }
        .to change(Product, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Coca-Cola", "value" => 7.5, "category_name" => category.name)
    end

    it "returns 404 when the category belongs to another store" do
      foreign = create(:category, user: other_store)
      post "/api/v1/products", params: { category_id: foreign.id, name: "X", value: 1 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for invalid data" do
      post "/api/v1/products", params: { category_id: category.id, name: "", value: -1 }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/products/:id" do
    it "updates an owned product and can move it to another owned category" do
      product = create(:product, user: store, category: category)
      target  = create(:category, user: store)

      put "/api/v1/products/#{product.id}",
          params: { name: "Novo", category_id: target.id }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(product.reload.name).to eq("Novo")
      expect(product.category_id).to eq(target.id)
    end

    it "returns 404 for another store's product" do
      product = create(:product, user: other_store)
      put "/api/v1/products/#{product.id}", params: { name: "X" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/products/:id" do
    it "removes an owned product" do
      product = create(:product, user: store, category: category)
      expect { delete "/api/v1/products/#{product.id}", headers: headers }
        .to change(Product, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end
end
