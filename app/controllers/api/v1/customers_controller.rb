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

      def statement
        customer = current_user.customers.find(params[:id])
        sales = customer.sales.includes(sale_items: :product).order(sale_date: :desc)
        txns = customer.cashback_transactions.order(created_at: :desc).includes(:sale_item)

        earned   = txns.earned.sum(:amount)
        redeemed = txns.redeemed.sum(:amount).abs
        expired  = txns.expired.sum(:amount).abs
        balance  = customer.balance

        redeemable_products = current_user.products
          .includes(:category)
          .where("redeem_points > 0")
          .order(:redeem_points)
          .map { |p|
            can_redeem = balance >= p.redeem_points
            {
              id: p.id, name: p.name, value: p.value.to_f,
              category_name: p.category.name, redeem_points: p.redeem_points.to_f,
              description: p.description,
              can_redeem: can_redeem,
              missing: can_redeem ? 0.0 : (p.redeem_points.to_f - balance.to_f).round(2)
            }
          }

        render json: {
          customer: customer_json(customer),
          unit: current_user.cashback_kind,
          balance: balance.to_f,
          earned_total: earned.to_f,
          redeemed_total: redeemed.to_f,
          expired_total: expired.to_f,
          min_redeem: current_user.cashback_min_redeem.to_f,
          redeemable_products: redeemable_products,
          purchases: sales.map { |s|
            {
              id: s.id, total: s.total.to_f, sale_date: s.sale_date,
              cashback_earned: s.sale_items.sum(&:cashback_earned).to_f,
              items: s.sale_items.map { |i|
                { product_name: i.product.name, quantity: i.quantity,
                  unit_price: i.unit_price.to_f, cashback_earned: i.cashback_earned.to_f }
              }
            }
          },
          transactions: txns.map { |t|
            {
              id: t.id, kind: t.kind, amount: t.amount.to_f, unit: t.unit,
              description: t.description, expires_at: t.expires_at,
              created_at: t.created_at, sale_id: t.sale_id
            }
          },
          messages: customer.message_deliveries.order(created_at: :desc).limit(20).map { |m|
            {
              id: m.id, channel: m.channel, template: m.template, status: m.status,
              body: m.body, error: m.error, sent_at: m.sent_at, created_at: m.created_at
            }
          }
        }
      end

      def redeem
        customer = current_user.customers.find(params[:id])
        tx = CashbackService.redeem(customer: customer, amount: params[:amount])
        render json: { ok: true, balance: customer.balance.to_f, transaction_id: tx.id }
      rescue CashbackService::BelowMinimum, CashbackService::InsufficientBalance, CashbackService::Error => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      private

      def customer_params
        params.permit(:name, :birth_date, :phone_number, :cpf, :whatsapp_opt_in)
      end

      def customer_json(customer)
        {
          id: customer.id,
          name: customer.name,
          birth_date: customer.birth_date,
          phone_number: customer.phone_number,
          cpf: customer.cpf,
          whatsapp_opt_in: customer.whatsapp_opt_in,
          available_credits: (customer.customer_credit&.available_credits || 0).to_f,
          unit: current_user.cashback_kind,
          created_at: customer.created_at
        }
      end
    end
  end
end
