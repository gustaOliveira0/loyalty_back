module Api
  module V1
    class CustomersController < ApplicationController
      include JwtAuthenticatable

      def index
        customers = current_user.customers.includes(:customer_credit)
        render json: customers.map { |c| customer_json(c) }
      end

      def show
        customer = current_user.customers.find(params[:id])
        render json: customer_json(customer)
      end

      def create
        customer = current_user.customers.create!(customer_params)
        render json: customer_json(customer), status: :created
      end

      def update
        customer = current_user.customers.find(params[:id])
        customer.update!(customer_params)
        render json: customer_json(customer)
      end

      def destroy
        customer = current_user.customers.find(params[:id])
        customer.destroy!
        render json: { message: "Cliente removido com sucesso" }
      end

      private

      def customer_params
        params.permit(:name, :birth_date, :phone_number, :cpf)
      end

      def customer_json(customer)
        {
          id: customer.id,
          name: customer.name,
          birth_date: customer.birth_date,
          phone_number: customer.phone_number,
          cpf: customer.cpf,
          available_credits: customer.customer_credit&.available_credits || 0,
          created_at: customer.created_at
        }
      end
    end
  end
end
