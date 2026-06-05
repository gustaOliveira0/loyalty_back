module Api
  module V1
    class StoreSettingsController < ApplicationController
      include JwtAuthenticatable
      before_action -> { require_permission!(:can_manage_settings) }, only: [:update]

      def show
        render json: settings_json(current_user)
      end

      def update
        current_user.update!(settings_params)
        render json: settings_json(current_user)
      end

      private

      def settings_params
        params.permit(:cashback_kind, :cashback_expires_in_days, :cashback_min_redeem)
      end

      def settings_json(user)
        {
          cashback_kind: user.cashback_kind,
          cashback_expires_in_days: user.cashback_expires_in_days,
          cashback_min_redeem: user.cashback_min_redeem.to_f,
          unit_label: user.cashback_unit_label
        }
      end
    end
  end
end
