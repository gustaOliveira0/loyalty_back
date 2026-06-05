module Api
  module V1
    class AuthController < ApplicationController
      def register
        user = User.create!(user_params)
        token = JwtAuthenticatable.encode(user_id: user.id)
        render json: { token: token, user: user_json(user) }, status: :created
      end

      def login
        email = params[:email].to_s.downcase.strip

        subject = User.find_by("LOWER(email) = ?", email) ||
                  Collaborator.active.find_by("LOWER(email) = ?", email)

        if subject&.authenticate(params[:password])
          if subject.is_a?(Collaborator)
            token = JwtAuthenticatable.encode(collaborator_id: subject.id, user_id: subject.user_id)
            render json: { token: token, user: collaborator_json(subject) }
          else
            token = JwtAuthenticatable.encode(user_id: subject.id)
            render json: { token: token, user: user_json(subject) }
          end
        else
          render json: { error: "Email ou senha inválidos" }, status: :unauthorized
        end
      end

      private

      def user_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def user_json(user)
        { id: user.id, name: user.name, email: user.email, role: "admin", permissions: nil }
      end

      def collaborator_json(collaborator)
        permissions = Collaborator::PERMISSION_FLAGS.each_with_object({}) do |flag, h|
          h[flag] = collaborator[flag]
        end
        { id: collaborator.id, name: collaborator.name, email: collaborator.email, role: "collaborator", permissions: permissions }
      end
    end
  end
end
