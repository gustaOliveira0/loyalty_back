require "rails_helper"

RSpec.describe "Api::V1::Public::Customers", type: :request do
  let(:store) { create(:user, name: "Loja do Bairro") }

  describe "GET /api/v1/public/store/:store_id" do
    it "returns the store name without authentication" do
      get "/api/v1/public/store/#{store.id}"
      expect(response).to have_http_status(:ok)
      expect(json["store_name"]).to eq("Loja do Bairro")
    end

    it "returns 404 for an unknown store" do
      get "/api/v1/public/store/0"
      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to be_present
    end
  end

  describe "POST /api/v1/public/customers" do
    let(:valid_params) do
      { store_id: store.id, name: "João", birth_date: "1995-03-10",
        phone_number: "11988887777", cpf: "52998224725", consent: true }
    end

    it "self-registers a customer without authentication when consent is given" do
      expect { post "/api/v1/public/customers", params: valid_params }
        .to change(Customer, :count).by(1)
        .and change(CustomerCredit, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["message"]).to include("Loja do Bairro")
    end

    it "records proof of consent (LGPD Art. 8)" do
      post "/api/v1/public/customers", params: valid_params
      customer = Customer.last
      expect(customer.consented_at).to be_present
      expect(customer.consent_version).to eq(Api::V1::Public::CustomersController::CONSENT_VERSION)
    end

    it "rejects registration without consent (LGPD Art. 7, I)" do
      expect { post "/api/v1/public/customers", params: valid_params.merge(consent: false) }
        .not_to change(Customer, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not return personal data (name/cpf) to anonymous requesters" do
      post "/api/v1/public/customers", params: valid_params
      expect(json).not_to have_key("customer_name")
      expect(json).not_to have_key("cpf")
    end

    it "attaches the new customer to the right store" do
      post "/api/v1/public/customers", params: valid_params
      expect(Customer.last.user_id).to eq(store.id)
    end

    it "returns 404 when the store does not exist" do
      post "/api/v1/public/customers", params: valid_params.merge(store_id: 0)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for invalid data" do
      post "/api/v1/public/customers", params: valid_params.merge(cpf: "")
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json["error"]).to be_present
    end

    it "returns a generic error (no titular enumeration) for a duplicate cpf" do
      create(:customer, user: store, cpf: "52998224725")
      post "/api/v1/public/customers", params: valid_params
      expect(response).to have_http_status(:unprocessable_entity)
      # Não pode revelar que o CPF já existe (evita enumeração de titulares).
      expect(response.body).not_to match(/cpf|já está em uso|already/i)
    end
  end
end
