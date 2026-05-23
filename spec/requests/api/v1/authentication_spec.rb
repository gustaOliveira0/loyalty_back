require "rails_helper"

# Cross-cutting JWT authentication behaviour (JwtAuthenticatable concern).
# We exercise it through a representative protected endpoint.
RSpec.describe "JWT authentication", type: :request do
  let(:user) { create(:user) }
  let(:protected_path) { "/api/v1/customers" }

  it "rejects requests without a token" do
    get protected_path
    expect(response).to have_http_status(:unauthorized)
    expect(json["error"]).to be_present
  end

  it "rejects a malformed/garbage token" do
    get protected_path, headers: { "Authorization" => "Bearer not.a.jwt" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects an expired token" do
    get protected_path, headers: { "Authorization" => "Bearer #{expired_token_for(user)}" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects a token signed with the wrong secret" do
    forged = JWT.encode({ user_id: user.id, exp: 1.day.from_now.to_i }, "wrong_secret", "HS256")
    get protected_path, headers: { "Authorization" => "Bearer #{forged}" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts a valid token" do
    get protected_path, headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
  end
end
