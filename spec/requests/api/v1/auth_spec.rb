require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/register" do
    let(:valid_params) do
      { name: "Padaria do Zé", email: "ze@padaria.com",
        password: "password123", password_confirmation: "password123" }
    end

    it "creates a user and returns a token" do
      expect { post "/api/v1/auth/register", params: valid_params }
        .to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["user"]).to include("email" => "ze@padaria.com", "name" => "Padaria do Zé")
    end

    it "never leaks the password digest in the payload" do
      post "/api/v1/auth/register", params: valid_params
      expect(json["user"]).not_to have_key("password_digest")
    end

    it "returns 422 with errors for invalid data" do
      post "/api/v1/auth/register", params: valid_params.merge(email: "")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["errors"]).to be_an(Array).and be_present
    end

    it "returns 422 for a duplicate email" do
      create(:user, email: "ze@padaria.com")
      post "/api/v1/auth/register", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) do
      create(:user, email: "owner@store.com",
                    password: "password123", password_confirmation: "password123")
    end

    it "returns a token for valid credentials" do
      post "/api/v1/auth/login", params: { email: "owner@store.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      expect(json["token"]).to be_present
      expect(json["user"]["id"]).to eq(user.id)
    end

    it "normalizes the email (case-insensitive, trimmed)" do
      post "/api/v1/auth/login", params: { email: "  OWNER@STORE.COM  ", password: "password123" }
      expect(response).to have_http_status(:ok)
    end

    it "returns 401 for a wrong password" do
      post "/api/v1/auth/login", params: { email: "owner@store.com", password: "nope" }
      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to be_present
    end

    it "returns 404 for an unknown email" do
      post "/api/v1/auth/login", params: { email: "ghost@store.com", password: "password123" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
