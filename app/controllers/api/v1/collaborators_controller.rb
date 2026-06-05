module Api
  module V1
    class CollaboratorsController < ApplicationController
      include JwtAuthenticatable
      before_action :admin_only!
      before_action :set_collaborator, only: [:show, :update, :destroy]

      def index
        collaborators = current_user.collaborators.order(:name)
        render json: collaborators.map { |c| collaborator_json(c) }
      end

      def show
        render json: collaborator_json(@collaborator)
      end

      def create
        collaborator = current_user.collaborators.build(collaborator_params)
        if collaborator.save
          render json: collaborator_json(collaborator), status: :created
        else
          render json: { errors: collaborator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @collaborator.update(update_params)
          render json: collaborator_json(@collaborator)
        else
          render json: { errors: @collaborator.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @collaborator.destroy!
        head :no_content
      end

      private

      def set_collaborator
        @collaborator = current_user.collaborators.find(params[:id])
      end

      def collaborator_params
        params.permit(
          :name, :cpf, :birth_date, :email, :password, :password_confirmation,
          *Collaborator::PERMISSION_FLAGS
        )
      end

      def update_params
        base = params.permit(
          :name, :cpf, :birth_date, :email, :active,
          *Collaborator::PERMISSION_FLAGS
        )
        if params[:password].present?
          base.merge(params.permit(:password, :password_confirmation))
        else
          base
        end
      end

      def collaborator_json(collaborator)
        permissions = Collaborator::PERMISSION_FLAGS.each_with_object({}) do |flag, h|
          h[flag] = collaborator[flag]
        end
        {
          id: collaborator.id,
          name: collaborator.name,
          cpf: collaborator.cpf,
          birth_date: collaborator.birth_date,
          email: collaborator.email,
          active: collaborator.active,
          permissions: permissions,
          created_at: collaborator.created_at
        }
      end
    end
  end
end
