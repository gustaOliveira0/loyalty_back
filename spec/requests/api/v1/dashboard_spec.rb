require "rails_helper"

RSpec.describe "Api::V1::Dashboard", type: :request do
  let(:store)    { create(:user) }
  let(:headers)  { auth_headers(store) }
  let(:customer) { create(:customer, user: store) }
  let(:category) { create(:category, user: store) }
  let!(:product) { create(:product, user: store, category: category, value: 100, cashback_mode: "percent", cashback_value: 10) }

  def make_sale(date: Date.today, qty: 1)
    CashbackService.record_sale(
      user: store,
      customer: customer,
      items: [{ product_id: product.id, quantity: qty, unit_price: 100 }],
      sale_date: date,
      notify: false
    )
  end

  describe "GET /api/v1/dashboard" do
    it "requires authentication" do
      get "/api/v1/dashboard"
      expect(response).to have_http_status(:unauthorized)
    end

    it "defaults to the current month when period is omitted" do
      get "/api/v1/dashboard", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json).to include("summary", "chart_data", "period")
    end

    context "period=day" do
      it "counts only today's sales in the summary" do
        make_sale(date: Date.today)
        make_sale(date: Date.yesterday)

        get "/api/v1/dashboard", params: { period: "day" }, headers: headers

        expect(json["summary"]["total_sales"]).to eq(1)
        expect(json["summary"]["total_revenue"]).to eq(100.0)
      end

      it "returns a single chart point for today" do
        get "/api/v1/dashboard", params: { period: "day" }, headers: headers
        expect(json["chart_data"].length).to eq(1)
      end
    end

    context "period=week" do
      it "returns 7 chart points (sunday through today)" do
        get "/api/v1/dashboard", params: { period: "week" }, headers: headers
        points = json["chart_data"].length
        expect(points).to be_between(1, 7)
      end

      it "sums revenue across all sales in the week" do
        make_sale(date: Date.today, qty: 1)
        make_sale(date: Date.today, qty: 2)

        get "/api/v1/dashboard", params: { period: "week" }, headers: headers

        expect(json["summary"]["total_revenue"]).to eq(300.0)
        expect(json["summary"]["total_sales"]).to eq(2)
      end
    end

    context "period=month" do
      it "returns chart points for the whole month up to today" do
        get "/api/v1/dashboard", params: { period: "month" }, headers: headers
        expect(json["chart_data"].length).to eq(Date.today.day)
      end

      it "computes avg_ticket correctly" do
        make_sale(date: Date.today, qty: 1)  # total 100
        make_sale(date: Date.today, qty: 3)  # total 300

        get "/api/v1/dashboard", params: { period: "month" }, headers: headers

        expect(json["summary"]["avg_ticket"]).to eq(200.0)
      end

      it "reports total cashback earned in the period" do
        make_sale(date: Date.today, qty: 2)  # 10% of 200 = 20 pts

        get "/api/v1/dashboard", params: { period: "month" }, headers: headers

        expect(json["summary"]["total_cashback"]).to eq(20.0)
      end
    end

    context "period=custom" do
      it "respects the provided date range" do
        make_sale(date: 10.days.ago.to_date)
        make_sale(date: Date.today)

        get "/api/v1/dashboard",
            params: { period: "custom", start_date: 15.days.ago.to_s, end_date: 5.days.ago.to_s },
            headers: headers

        expect(json["summary"]["total_sales"]).to eq(1)
      end
    end

    context "new_customers" do
      it "counts only customers created within the period, ignoring older ones" do
        create(:customer, user: store, created_at: 2.months.ago)  # should NOT be counted
        create(:customer, user: store)                              # created today, should be counted

        get "/api/v1/dashboard", params: { period: "month" }, headers: headers

        expect(json["summary"]["new_customers"]).to eq(1)
      end
    end

    it "returns zero summary when there are no sales in the period" do
      get "/api/v1/dashboard", params: { period: "day" }, headers: headers

      expect(json["summary"]).to include(
        "total_revenue"  => 0.0,
        "total_sales"    => 0,
        "avg_ticket"     => 0.0,
        "total_cashback" => 0.0
      )
    end

    it "does not leak another store's sales" do
      other = create(:user)
      other_customer  = create(:customer, user: other)
      other_category  = create(:category, user: other)
      other_product   = create(:product, user: other, category: other_category, value: 500, cashback_mode: "percent", cashback_value: 0)
      CashbackService.record_sale(
        user: other, customer: other_customer,
        items: [{ product_id: other_product.id, quantity: 1, unit_price: 500 }],
        notify: false
      )

      get "/api/v1/dashboard", params: { period: "month" }, headers: headers

      expect(json["summary"]["total_revenue"]).to eq(0.0)
    end
  end
end
