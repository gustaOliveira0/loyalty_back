module Api
  module V1
    module Public
      class CustomersController < ApplicationController
        # No authentication — public endpoint for customer self-registration

        # Versão atual do termo de consentimento aceito no formulário público.
        # Incremente quando o texto/finalidade do tratamento mudar (LGPD Art. 8, §6).
        CONSENT_VERSION = "1.0".freeze

        def store_info
          user = User.find(params[:store_id])
          render json: { store_name: user.name }
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Loja não encontrada" }, status: :not_found
        end

        def create
          user = User.find(params[:store_id])

          # LGPD (Art. 7, I / Art. 8) — sem consentimento não há base legal para o
          # tratamento neste fluxo de auto-cadastro. Bloqueamos e registramos a
          # comprovação (momento, IP e versão do termo) quando concedido.
          unless consent_given?
            return render json: {
              error: "É necessário ler e aceitar a Política de Privacidade para concluir o cadastro."
            }, status: :unprocessable_entity
          end

          user.customers.create!(
            customer_params.merge(
              consented_at: Time.current,
              consent_ip: request.remote_ip,
              consent_version: CONSENT_VERSION
            )
          )

          render json: {
            message: "Cadastro realizado com sucesso! Bem-vindo ao programa de fidelidade de #{user.name}.",
            consent_version: CONSENT_VERSION
          }, status: :created
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Loja não encontrada" }, status: :not_found
        rescue ActiveRecord::RecordInvalid
          # LGPD (Art. 6, VI/VII) — neste endpoint público NÃO devolvemos os erros
          # detalhados (ex.: "CPF já está em uso"), pois isso permitiria a um
          # terceiro descobrir se uma pessoa já é cliente da loja (enumeração de
          # titulares). Mensagem genérica para o público.
          render json: {
            error: "Não foi possível concluir o cadastro. Verifique os dados informados e tente novamente."
          }, status: :unprocessable_entity
        end

        private

        # Não devolvemos customer_name/CPF no corpo: confirmar o nome cadastrado a
        # um requisitante anônimo também é exposição desnecessária de dado pessoal.
        def customer_params
          params.permit(:name, :birth_date, :phone_number, :cpf)
        end

        def consent_given?
          ActiveModel::Type::Boolean.new.cast(params[:consent])
        end
      end
    end
  end
end
