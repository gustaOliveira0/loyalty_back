module Api
  module V1
    class ProfileController < ApplicationController
      include JwtAuthenticatable
      before_action :admin_only!

      def show
        render json: profile_json(current_user)
      end

      def update
        if profile_params[:password].present?
          unless current_user.authenticate(profile_params[:current_password].to_s)
            render json: { errors: ["Senha atual incorreta"] }, status: :unprocessable_entity
            return
          end
        end

        current_user.update!(sanitized_params)
        render json: profile_json(current_user)
      end

      private

      def profile_params
        params.permit(:name, :email, :current_password, :password, :password_confirmation)
      end

      def sanitized_params
        profile_params.except(:current_password)
      end

      def profile_json(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          created_at: user.created_at
        }
      end
    end
  end
end
