require "rails_helper"

RSpec.describe "Api::V1::Qrcode", type: :request do
  let(:store) { create(:user, name: "Loja Central") }

  describe "GET /api/v1/qrcode" do
    it "returns the public registration URL pointing at the current store" do
      get "/api/v1/qrcode", headers: auth_headers(store)

      expect(response).to have_http_status(:ok)
      expect(json["store_id"]).to eq(store.id)
      expect(json["store_name"]).to eq("Loja Central")
      expect(json["url"]).to end_with("/cadastro/#{store.id}")
    end

    it "requires authentication" do
      get "/api/v1/qrcode"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
