module Api
  module V1
    class SalesController < ApplicationController
      include JwtAuthenticatable
      before_action -> { require_permission!(:can_create_sales) }, only: [:create]

      def index
        sales = current_user.sales.includes(:customer, sale_items: :product).order(sale_date: :desc)
        render json: sales.map { |s| sale_json(s) }
      end

      def show
        sale = current_user.sales.includes(sale_items: :product).find(params[:id])
        render json: sale_json(sale, include_items: true)
      end

      def create
        customer = current_user.customers.find(params[:customer_id])

        sale = CashbackService.record_sale(
          user: current_user,
          customer: customer,
          items: items_param,
          sale_date: params[:sale_date]
        )

        render json: sale_json(sale, include_items: true), status: :created
      rescue CashbackService::Error => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def items_param
        raw = params[:items] || []
        raw = raw.values if raw.is_a?(ActionController::Parameters) || raw.is_a?(Hash)
        Array(raw).map do |i|
          h = i.respond_to?(:to_unsafe_h) ? i.to_unsafe_h : i.to_h
          { product_id: h["product_id"] || h[:product_id],
            quantity:   h["quantity"]   || h[:quantity] || 1,
            unit_price: h["unit_price"] || h[:unit_price] }
        end
      end

      def sale_json(sale, include_items: false)
        json = {
          id: sale.id,
          customer_id: sale.customer_id,
          customer_name: sale.customer.name,
          total: sale.total.to_f,
          sale_date: sale.sale_date,
          created_at: sale.created_at,
          cashback_earned: sale.sale_items.sum(&:cashback_earned).to_f
        }
        if include_items
          json[:items] = sale.sale_items.map do |item|
            {
              id: item.id,
              product_id: item.product_id,
              product_name: item.product.name,
              quantity: item.quantity,
              unit_price: item.unit_price.to_f,
              subtotal: item.subtotal.to_f,
              cashback_mode: item.cashback_mode,
              cashback_value: item.cashback_value.to_f,
              cashback_earned: item.cashback_earned.to_f
            }
          end
        end
        json
      end
    end
  end
end
