# Helpers for authenticating request specs.
#
# The API expects `Authorization: Bearer <jwt>` (see JwtAuthenticatable).
# These helpers keep request specs focused on behaviour instead of plumbing.
module AuthHelper
  def auth_headers(user)
    token = JwtAuthenticatable.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  def collaborator_auth_headers(collaborator)
    token = JwtAuthenticatable.encode(collaborator_id: collaborator.id, user_id: collaborator.user_id)
    { "Authorization" => "Bearer #{token}" }
  end

  def expired_token_for(user)
    payload = { user_id: user.id, exp: 1.day.ago.to_i }
    JWT.encode(payload, JwtAuthenticatable::SECRET, "HS256")
  end
end
