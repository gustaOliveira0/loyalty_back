module Api
  module V1
    class SalesController < ApplicationController
      include JwtAuthenticatable

      def index
        sales = current_user.sales.includes(:customer).order(sale_date: :desc)
        render json: sales.map { |s| sale_json(s) }
      end

      def show
        sale = current_user.sales.find(params[:id])
        render json: sale_json(sale)
      end

      def create
        customer = current_user.customers.find(params[:customer_id])
        sale = current_user.sales.create!(
          customer: customer,
          total: params[:total],
          sale_date: params[:sale_date] || Time.current
        )
        render json: sale_json(sale), status: :created
      end

      private

      def sale_json(sale)
        {
          id: sale.id,
          customer_id: sale.customer_id,
          customer_name: sale.customer.name,
          total: sale.total.to_f,
          sale_date: sale.sale_date,
          created_at: sale.created_at
        }
      end
    end
  end
end
