module Api
  module V1
    class AuthController < ApplicationController
      def register
        user = User.create!(user_params)
        token = JwtAuthenticatable.encode(user_id: user.id)
        render json: { token: token, user: user_json(user) }, status: :created
      end

      def login
        user = User.find_by!(email: params[:email].downcase.strip)

        if user.authenticate(params[:password])
          token = JwtAuthenticatable.encode(user_id: user.id)
          render json: { token: token, user: user_json(user) }
        else
          render json: { error: "Email ou senha inválidos" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def user_json(user)
        { id: user.id, name: user.name, email: user.email }
      end
    end
  end
end
