module Api
  module V1
    module Public
      class CustomersController < ApplicationController
        # No authentication — public endpoint for customer self-registration

        def store_info
          user = User.find(params[:store_id])
          render json: { store_name: user.name }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Loja não encontrada" }, status: :not_found
        end

        def create
          user = User.find(params[:store_id])
          customer = user.customers.create!(customer_params)
          render json: {
            message: "Cadastro realizado com sucesso! Bem-vindo ao programa de fidelidade de #{user.name}.",
            customer_name: customer.name
          }, status: :created
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Loja não encontrada" }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
        end

        private

        def customer_params
          params.permit(:name, :birth_date, :phone_number, :cpf)
        end
      end
    end
  end
end
