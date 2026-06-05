module Api
  module V1
    class CreditRulesController < ApplicationController
      include JwtAuthenticatable
      before_action -> { require_permission!(:can_manage_credit_rules) }, only: [:create, :update, :destroy]

      def index
        rules = current_user.credit_rules.order(:spend_amount)
        render json: rules.map { |r| rule_json(r) }
      end

      def show
        rule = current_user.credit_rules.find(params[:id])
        render json: rule_json(rule)
      end

      def create
        rule = current_user.credit_rules.create!(rule_params)
        render json: rule_json(rule), status: :created
      end

      def update
        rule = current_user.credit_rules.find(params[:id])
        rule.update!(rule_params)
        render json: rule_json(rule)
      end

      def destroy
        rule = current_user.credit_rules.find(params[:id])
        rule.destroy!
        render json: { message: "Regra de crédito removida com sucesso" }
      end

      private

      def rule_params
        params.permit(:spend_amount, :credit_amount)
      end

      def rule_json(rule)
        {
          id: rule.id,
          spend_amount: rule.spend_amount.to_f,
          credit_amount: rule.credit_amount,
          description: "A cada R$ #{rule.spend_amount} gastos, o cliente ganha #{rule.credit_amount} créditos",
          created_at: rule.created_at
        }
      end
    end
  end
end
