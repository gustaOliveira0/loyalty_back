# Helpers for authenticating request specs.
#
# The API expects `Authorization: Bearer <jwt>` (see JwtAuthenticatable).
# These helpers keep request specs focused on behaviour instead of plumbing.
module AuthHelper
  # Valid headers for the given user.
  def auth_headers(user)
    token = JwtAuthenticatable.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  # An explicitly expired token, to assert the API rejects it.
  def expired_token_for(user)
    payload = { user_id: user.id, exp: 1.day.ago.to_i }
    JWT.encode(payload, JwtAuthenticatable::SECRET, "HS256")
  end
end
