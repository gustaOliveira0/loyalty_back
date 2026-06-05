require "rails_helper"

RSpec.describe "Api::V1::Collaborators", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/collaborators" do
    let!(:c1) { create(:collaborator, user: user) }
    let!(:c2) { create(:collaborator, user: other_user) }

    it "returns only collaborators of the current user" do
      get "/api/v1/collaborators", headers: headers
      expect(response).to have_http_status(:ok)
      ids = response.parsed_body.map { |c| c["id"] }
      expect(ids).to include(c1.id)
      expect(ids).not_to include(c2.id)
    end

    it "returns 401 without token" do
      get "/api/v1/collaborators"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 when called by a collaborator" do
      collab = create(:collaborator, user: user)
      get "/api/v1/collaborators", headers: collaborator_auth_headers(collab)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/collaborators/:id" do
    let(:collab) { create(:collaborator, user: user) }

    it "returns the collaborator with permissions" do
      get "/api/v1/collaborators/#{collab.id}", headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(collab.id)
      expect(body["permissions"]).to be_a(Hash)
      expect(body["permissions"]).to have_key("can_create_sales")
    end

    it "returns 404 for a collaborator of another user" do
      other_collab = create(:collaborator, user: other_user)
      get "/api/v1/collaborators/#{other_collab.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/collaborators" do
    let(:valid_params) do
      {
        name: "Maria Teste",
        cpf: "11122233344",
        birth_date: "1990-05-15",
        email: "maria@teste.com",
        password: "senha123",
        password_confirmation: "senha123",
        can_edit_customers: true,
        can_delete_customers: false,
        can_create_sales: true,
        can_manage_products: false,
        can_manage_categories: false,
        can_manage_credit_rules: false,
        can_view_dashboard: true,
        can_manage_settings: false
      }
    end

    it "creates a collaborator" do
      expect {
        post "/api/v1/collaborators", params: valid_params, headers: headers
      }.to change(Collaborator, :count).by(1)
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["name"]).to eq("Maria Teste")
      expect(body["permissions"]["can_delete_customers"]).to be false
    end

    it "returns 422 with invalid data" do
      post "/api/v1/collaborators", params: valid_params.merge(email: "invalid"), headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to be_present
    end

    it "returns 403 when called by a collaborator" do
      collab = create(:collaborator, user: user)
      post "/api/v1/collaborators", params: valid_params, headers: collaborator_auth_headers(collab)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/collaborators/:id" do
    let(:collab) { create(:collaborator, user: user, active: true, can_edit_customers: true) }

    it "updates collaborator attributes" do
      patch "/api/v1/collaborators/#{collab.id}",
        params: { name: "Nome Atualizado", can_edit_customers: false },
        headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["name"]).to eq("Nome Atualizado")
      expect(body["permissions"]["can_edit_customers"]).to be false
    end

    it "can deactivate a collaborator" do
      patch "/api/v1/collaborators/#{collab.id}",
        params: { active: false },
        headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["active"]).to be false
    end

    it "can reactivate a collaborator" do
      collab.update!(active: false)
      patch "/api/v1/collaborators/#{collab.id}",
        params: { active: true },
        headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["active"]).to be true
    end

    it "updates password when provided" do
      patch "/api/v1/collaborators/#{collab.id}",
        params: { password: "novasenha123", password_confirmation: "novasenha123" },
        headers: headers
      expect(response).to have_http_status(:ok)
      collab.reload
      expect(collab.authenticate("novasenha123")).to be_truthy
    end
  end

  describe "DELETE /api/v1/collaborators/:id" do
    let!(:collab) { create(:collaborator, user: user) }

    it "destroys the collaborator" do
      expect {
        delete "/api/v1/collaborators/#{collab.id}", headers: headers
      }.to change(Collaborator, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 when called by a collaborator" do
      other = create(:collaborator, user: user)
      delete "/api/v1/collaborators/#{collab.id}", headers: collaborator_auth_headers(other)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
