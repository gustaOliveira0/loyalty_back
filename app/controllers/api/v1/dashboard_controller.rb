module Api
  module V1
    class DashboardController < ApplicationController
      include JwtAuthenticatable

      def show
        start_date, end_date = resolve_period

        sales_in_period = current_user.sales
          .includes(:customer, sale_items: {})
          .where(sale_date: start_date..end_date)

        total_revenue   = sales_in_period.sum(:total).to_f
        total_sales     = sales_in_period.count
        avg_ticket      = total_sales > 0 ? (total_revenue / total_sales).round(2) : 0.0
        total_cashback  = current_user.sales
          .joins(:sale_items)
          .where(sale_date: start_date..end_date)
          .sum("sale_items.cashback_earned").to_f

        new_customers = current_user.customers
          .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          .count

        chart_data = build_chart_data(sales_in_period, start_date, end_date)

        render json: {
          period: { start_date: start_date, end_date: end_date },
          summary: {
            total_revenue: total_revenue,
            total_sales: total_sales,
            avg_ticket: avg_ticket,
            total_cashback: total_cashback,
            new_customers: new_customers
          },
          chart_data: chart_data
        }
      end

      private

      def resolve_period
        case params[:period]
        when "day"
          date = Date.today
          [date, date]
        when "week"
          [Date.today.beginning_of_week(:sunday), Date.today]
        when "month"
          [Date.today.beginning_of_month, Date.today]
        when "custom"
          start_d = Date.parse(params[:start_date]) rescue Date.today.beginning_of_month
          end_d   = Date.parse(params[:end_date])   rescue Date.today
          [start_d, [end_d, Date.today].min]
        else
          [Date.today.beginning_of_month, Date.today]
        end
      end

      def build_chart_data(sales, start_date, end_date)
        grouped = sales.group_by { |s| s.sale_date.to_date }

        (start_date..end_date).map do |date|
          day_sales = grouped[date] || []
          {
            date: date.strftime("%Y-%m-%d"),
            label: date.strftime("%d/%m"),
            revenue: day_sales.sum(&:total).to_f,
            sales_count: day_sales.size
          }
        end
      end
    end
  end
end
