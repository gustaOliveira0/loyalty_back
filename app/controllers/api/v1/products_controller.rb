module Api
  module V1
    class ProductsController < ApplicationController
      include JwtAuthenticatable
      before_action -> { require_permission!(:can_manage_products) }, only: [:create, :update, :destroy]

      def index
        products = current_user.products.includes(:category).order(:name)
        products = products.where(category_id: params[:category_id]) if params[:category_id]
        render json: products.map { |p| product_json(p) }
      end

      def show
        product = current_user.products.find(params[:id])
        render json: product_json(product)
      end

      def create
        category = current_user.categories.find(params[:category_id])
        product = current_user.products.create!(
          product_params.merge(category: category)
        )
        render json: product_json(product), status: :created
      end

      def update
        product = current_user.products.find(params[:id])
        attrs = product_params.to_h
        if params[:category_id]
          category = current_user.categories.find(params[:category_id])
          attrs[:category] = category
        end
        product.update!(attrs)
        render json: product_json(product)
      end

      def destroy
        product = current_user.products.find(params[:id])
        product.destroy!
        render json: { message: "Produto removido com sucesso" }
      end

      private

      def product_params
        params.permit(:name, :value, :description, :cashback_mode, :cashback_value, :redeem_points)
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          value: product.value.to_f,
          description: product.description,
          category_id: product.category_id,
          category_name: product.category.name,
          cashback_mode: product.cashback_mode,
          cashback_value: product.cashback_value.to_f,
          redeem_points: product.redeem_points.to_f,
          created_at: product.created_at
        }
      end
    end
  end
end
