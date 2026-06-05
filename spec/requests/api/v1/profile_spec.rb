require "rails_helper"

RSpec.describe "Api::V1::Profile", type: :request do
  let(:user) { create(:user, name: "Loja Original", email: "original@loja.com",
    password: "senha123", password_confirmation: "senha123") }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/profile" do
    it "returns the current user's profile" do
      get "/api/v1/profile", headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["id"]).to eq(user.id)
      expect(body["name"]).to eq("Loja Original")
      expect(body["email"]).to eq("original@loja.com")
      expect(body).not_to have_key("password_digest")
    end

    it "returns 401 without token" do
      get "/api/v1/profile"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 403 for a collaborator" do
      collab = create(:collaborator, user: user)
      get "/api/v1/profile", headers: collaborator_auth_headers(collab)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/profile" do
    it "updates name and email" do
      patch "/api/v1/profile",
        params: { name: "Loja Nova", email: "nova@loja.com" },
        headers: headers
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["name"]).to eq("Loja Nova")
      expect(body["email"]).to eq("nova@loja.com")
      expect(user.reload.name).to eq("Loja Nova")
      expect(user.reload.email).to eq("nova@loja.com")
    end

    it "updates password when current_password is correct" do
      patch "/api/v1/profile",
        params: { current_password: "senha123", password: "novaSenha456", password_confirmation: "novaSenha456" },
        headers: headers
      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate("novaSenha456")).to be_truthy
    end

    it "rejects password change when current_password is wrong" do
      patch "/api/v1/profile",
        params: { current_password: "errada", password: "novaSenha456", password_confirmation: "novaSenha456" },
        headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Senha atual incorreta")
      expect(user.reload.authenticate("novaSenha456")).to be_falsy
    end

    it "rejects mismatched password confirmation" do
      patch "/api/v1/profile",
        params: { current_password: "senha123", password: "nova123", password_confirmation: "diferente" },
        headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate email" do
      create(:user, email: "ocupado@loja.com")
      patch "/api/v1/profile",
        params: { email: "ocupado@loja.com" },
        headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 403 for a collaborator" do
      collab = create(:collaborator, user: user)
      patch "/api/v1/profile",
        params: { name: "Hacker" },
        headers: collaborator_auth_headers(collab)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 401 without token" do
      patch "/api/v1/profile", params: { name: "X" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
