require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  let(:store)       { create(:user) }
  let(:other_store) { create(:user) }
  let(:headers)     { auth_headers(store) }

  describe "GET /api/v1/categories" do
    it "lists only the store's categories ordered by name, with products_count" do
      bebidas = create(:category, user: store, name: "Bebidas")
      acai    = create(:category, user: store, name: "Açaí")
      create(:product, category: bebidas, user: store)
      create(:category, user: other_store)

      get "/api/v1/categories", headers: headers

      expect(json.map { |c| c["name"] }).to eq(["Açaí", "Bebidas"])
      expect(json.find { |c| c["id"] == bebidas.id }["products_count"]).to eq(1)
      expect(json.find { |c| c["id"] == acai.id }["products_count"]).to eq(0)
    end

    it "requires authentication" do
      get "/api/v1/categories"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/categories" do
    it "creates a category" do
      expect { post "/api/v1/categories", params: { name: "Doces" }, headers: headers }
        .to change(Category, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json).to include("name" => "Doces", "products_count" => 0)
    end

    it "returns 422 for a blank name" do
      post "/api/v1/categories", params: { name: "" }, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PUT /api/v1/categories/:id" do
    it "updates an owned category" do
      category = create(:category, user: store, name: "Velho")
      put "/api/v1/categories/#{category.id}", params: { name: "Novo" }, headers: headers
      expect(response).to have_http_status(:ok)
      expect(category.reload.name).to eq("Novo")
    end

    it "returns 404 for another store's category" do
      category = create(:category, user: other_store)
      put "/api/v1/categories/#{category.id}", params: { name: "X" }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/categories/:id" do
    it "removes an owned category and its products" do
      category = create(:category, user: store)
      create(:product, category: category, user: store)

      expect { delete "/api/v1/categories/#{category.id}", headers: headers }
        .to change(Category, :count).by(-1)
        .and change(Product, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end
  end
end
