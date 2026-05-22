module Api
  module V1
    class QrcodeController < ApplicationController
      include JwtAuthenticatable

      FRONTEND_URL = ENV.fetch("FRONTEND_URL", "http://localhost:5173")

      def show
        registration_url = "#{FRONTEND_URL}/cadastro/#{current_user.id}"
        render json: {
          url: registration_url,
          store_name: current_user.name,
          store_id: current_user.id
        }
      end
    end
  end
end
