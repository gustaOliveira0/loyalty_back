require "rails_helper"

RSpec.describe "Collaborator Permission Guards", type: :request do
  let(:user) { create(:user) }
  let(:customer) { create(:customer, user: user) }
  let(:category) { create(:category, user: user) }
  let(:product) { create(:product, user: user, category: category) }

  shared_context "full-access collaborator" do
    let(:collaborator) { create(:collaborator, user: user) }
    let(:headers) { collaborator_auth_headers(collaborator) }
  end

  shared_context "restricted collaborator" do
    let(:collaborator) { create(:collaborator, :restricted, user: user) }
    let(:headers) { collaborator_auth_headers(collaborator) }
  end

  describe "Customers" do
    context "with can_edit_customers = false" do
      include_context "restricted collaborator"

      it "blocks PATCH /customers/:id" do
        patch "/api/v1/customers/#{customer.id}", params: { name: "X" }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with can_delete_customers = false" do
      include_context "restricted collaborator"

      it "blocks DELETE /customers/:id" do
        delete "/api/v1/customers/#{customer.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with full permissions" do
      include_context "full-access collaborator"

      it "allows GET /customers" do
        get "/api/v1/customers", headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "allows PATCH /customers/:id" do
        patch "/api/v1/customers/#{customer.id}", params: { name: customer.name }, headers: headers
        expect(response).to have_http_status(:ok)
      end

      it "allows DELETE /customers/:id" do
        delete "/api/v1/customers/#{customer.id}", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Sales" do
    context "with can_create_sales = false" do
      include_context "restricted collaborator"

      it "blocks POST /sales" do
        post "/api/v1/sales", params: { customer_id: customer.id, items: [] }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with full permissions" do
      include_context "full-access collaborator"

      it "allows GET /sales" do
        get "/api/v1/sales", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Products" do
    context "with can_manage_products = false" do
      include_context "restricted collaborator"

      it "blocks POST /products" do
        post "/api/v1/products", params: { name: "P", value: 10, category_id: category.id },
          headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "blocks PATCH /products/:id" do
        patch "/api/v1/products/#{product.id}", params: { name: "X" }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "blocks DELETE /products/:id" do
        delete "/api/v1/products/#{product.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "still allows GET /products (read-only)" do
        get "/api/v1/products", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Categories" do
    context "with can_manage_categories = false" do
      include_context "restricted collaborator"

      it "blocks POST /categories" do
        post "/api/v1/categories", params: { name: "Nova" }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "still allows GET /categories" do
        get "/api/v1/categories", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Credit Rules" do
    let!(:rule) { create(:credit_rule, user: user) }

    context "with can_manage_credit_rules = false" do
      include_context "restricted collaborator"

      it "blocks POST /credit_rules" do
        post "/api/v1/credit_rules", params: { spend_amount: 100, credit_amount: 10 }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "blocks DELETE /credit_rules/:id" do
        delete "/api/v1/credit_rules/#{rule.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Store Settings" do
    context "with can_manage_settings = false (default)" do
      include_context "restricted collaborator"

      it "blocks PUT /store_settings" do
        put "/api/v1/store_settings", params: { cashback_kind: "money" }, headers: headers
        expect(response).to have_http_status(:forbidden)
      end

      it "allows GET /store_settings" do
        get "/api/v1/store_settings", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "Collaborator management (admin only)" do
    include_context "full-access collaborator"

    it "blocks GET /collaborators for a collaborator" do
      get "/api/v1/collaborators", headers: headers
      expect(response).to have_http_status(:forbidden)
    end

    it "blocks POST /collaborators for a collaborator" do
      post "/api/v1/collaborators", params: { name: "X" }, headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "Inactive collaborator" do
    let(:collaborator) { create(:collaborator, :inactive, user: user) }
    let(:headers) { collaborator_auth_headers(collaborator) }

    it "is rejected on any request" do
      get "/api/v1/customers", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
