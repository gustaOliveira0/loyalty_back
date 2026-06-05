module Api
  module V1
    class CategoriesController < ApplicationController
      include JwtAuthenticatable
      before_action -> { require_permission!(:can_manage_categories) }, only: [:create, :update, :destroy]

      def index
        categories = current_user.categories.order(:name)
        render json: categories.map { |c| category_json(c) }
      end

      def show
        category = current_user.categories.find(params[:id])
        render json: category_json(category)
      end

      def create
        category = current_user.categories.create!(category_params)
        render json: category_json(category), status: :created
      end

      def update
        category = current_user.categories.find(params[:id])
        category.update!(category_params)
        render json: category_json(category)
      end

      def destroy
        category = current_user.categories.find(params[:id])
        category.destroy!
        render json: { message: "Categoria removida com sucesso" }
      end

      private

      def category_params
        params.permit(:name)
      end

      def category_json(category)
        {
          id: category.id,
          name: category.name,
          products_count: category.products.count,
          created_at: category.created_at
        }
      end
    end
  end
end
