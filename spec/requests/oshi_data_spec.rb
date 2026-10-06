require "rails_helper"

RSpec.describe "Oshi data", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:date) { Date.new(2026, 10, 6) }
  let(:oshi) { create(:oshi, :approved, name: "推しA") }
  let(:second_oshi) { create(:oshi, :rejected, name: "推しB") }

  around { |example| travel_to(date) { example.run } }

  def login
    post user_session_path, params: { user: { email: user.email, password: "password123" } }
  end

  def document
    Nokogiri::HTML(response.body)
  end

  def activity(owner: user, oshis: [ oshi ], **attributes)
    record = build(:activity, :without_oshis, user: owner, **attributes)
    Activities::Save.call(activity: record, oshi_ids: oshis.map(&:id))
  end

  it "requires login" do
    get oshi_data_path
    expect(response).to redirect_to(new_user_session_path)
  end

  context "when signed in" do
    before { login }

    it "renders accessible empty sections, zero costs, and existing registration and management links" do
      get oshi_data_path
      expect(response).to have_http_status(:ok)
      expect(document.at_css("title").text).to eq("推し活データ | OshiLog")
      expect(document.at_css("main h1").text).to eq("推し活データ")
      expect(document.at_css("main").text).not_to include("準備中")
      expect(document.at_css("#activity-count").text).to eq("0回")
      expect(document.at_css("#activity-amount").text).to eq("支出記録なし")
      expect(document.at_css("#oshi-history").text).to eq("推しが登録されていません")
      expect(document.at_css("#data-highlight").text).to eq("比較できる活動記録がまだありません。")
      expect(document.at_css("#monthly-fixed-cost").text).to eq("0円")
      expect(document.at_css("#yearly-fixed-cost").text).to eq("0円")
      expect(document.css(".monthly-bars li").size).to eq(10)
      expect(document.css(".monthly-bars .data-bar-value").map(&:text)).to eq([ "0回" ] * 10)
      expect(document.css(".data-bar").map { |bar| bar["style"] }).to all(eq("width: 0%"))
      { new_oshi_path => "推しを登録する", new_activity_path => "記録する", activities_path => "活動記録一覧を見る", subscriptions_path => "固定費を管理する" }.each do |path, text|
        expect(document.at_css("main a[href='#{path}']").text).to eq(text)
      end
      expect(document.css(".data-filter label").map { |label| label["for"] }).to eq([ "year", "oshi_id" ])
      expect(document.at_css(".data-filter")["method"]).to eq("get")
      expect(document.at_css("#year option[selected]")["value"]).to eq("2026")
    end

    it "shows only owned aggregates, options and histories, including shared common activities" do
      create(:user_oshi, user: user, oshi: oshi, started_period: "2023/05")
      create(:user_oshi, user: user, oshi: second_oshi, ended_period: "2025")
      activity(amount: 1000)
      activity(amount: 1000, oshis: [ oshi, second_oshi ], activity_type: "配信視聴")
      create(:subscription, user: user, amount: 1200, oshis: [ oshi, second_oshi ])
      create(:subscription, :yearly, user: user, amount: 6000)
      other = create(:user)
      foreign_oshi = create(:oshi, name: "他人だけの推し")
      create(:user_oshi, user: other, oshi: foreign_oshi)
      create(:user_oshi, user: other, oshi: oshi, started_period: "1990")
      activity(owner: other, amount: 90_000, occurred_on: Date.new(2022, 1, 1))
      activity(owner: other, amount: 90_000)
      create(:subscription, user: other, amount: 80_000)
      get oshi_data_path
      expect(document.at_css("#activity-count").text).to eq("2回")
      expect(document.at_css("#activity-amount").text).to eq("2,000円")
      expect(document.at_css(".data-summary").text).to include("月平均 200円", "前年同期 +2回")
      expect(document.css(".data-categories .data-row").map(&:text).map(&:strip)).to include("ライブ・イベント50%（1回）", "配信視聴50%（1回）")
      expect(document.css(".data-oshis li").map(&:text)).to eq([ "推しA2回", "推しB1回" ])
      expect(document.at_css("#monthly-fixed-cost").text).to eq("1,200円")
      expect(document.at_css("#yearly-fixed-cost").text).to eq("6,000円")
      expect(document.css("#year option").map { |option| option["value"] }).to eq([ "2026" ])
      expect(document.at_css("main").text).not_to include("他人だけの推し", "1990", "90,000", "80,000")
      get oshi_data_path, params: { oshi_id: oshi.id }
      expect(document.at_css("#activity-count").text).to eq("2回")
      expect(document.at_css("#activity-amount").text).to eq("1,000円")
      expect(document.at_css("#oshi-history").text).to eq("2023年5月から → 現在")
      expect(document.css(".data-oshis li").map(&:text)).to eq([ "推しA2回" ])
      expect(document.at_css("main").text).to include("複数推しの共通支出は推し別支出に含みません")
      get oshi_data_path, params: { oshi_id: second_oshi.id }
      expect(document.at_css("#activity-amount").text).to eq("0円")
    end

    it "switches years, excluding future records while keeping current costs unchanged" do
      create(:user_oshi, user: user, oshi: oshi)
      activity(amount: 2400, occurred_on: Date.new(2025, 12, 31))
      activity(amount: 1000, occurred_on: date)
      activity(amount: 90_000, occurred_on: date + 1)
      create(:subscription, user: user, amount: 500)
      get oshi_data_path
      expect(document.at_css("#activity-count").text).to eq("1回")
      expect(document.at_css("#activity-amount").text).to eq("1,000円")
      get oshi_data_path, params: { year: "2025", oshi_id: oshi.id }
      expect(response).to have_http_status(:ok)
      expect(document.at_css("#year option[selected]")["value"]).to eq("2025")
      expect(document.at_css("#activity-amount").text).to eq("2,400円")
      expect(document.at_css(".data-summary").text).to include("月平均 200円")
      expect(document.css(".monthly-bars li").size).to eq(12)
      expect(document.css(".monthly-bars li").last.text).to include("12月", "1回")
      expect(document.at_css("#monthly-fixed-cost").text).to eq("500円")
    end

    it "distinguishes unrecorded amounts and zero yen" do
      create(:user_oshi, user: user, oshi: oshi)
      record = activity(amount: nil)
      get oshi_data_path
      expect(document.at_css("#activity-amount").text).to eq("支出記録なし")
      expect(document.at_css(".data-summary").text).to include("月平均 —")
      record.update!(amount: 0)
      get oshi_data_path
      expect(document.at_css("#activity-amount").text).to eq("0円")
      expect(document.at_css(".data-summary").text).to include("月平均 0円")
    end

    it "renders a deterministic category insight with its comparison dates" do
      create(:user_oshi, user: user, oshi: oshi)
      activity(occurred_on: Date.new(2026, 5, 1), activity_type: "その他")
      activity(occurred_on: date)
      get oshi_data_path
      expect(document.at_css("#data-highlight").text).to eq("最近3か月は「ライブ・イベント」の割合が増えています。")
      expect(document.at_css(".data-insight").text).to include("2026/8/1〜2026/10/6", "2026/5/1〜2026/7/31")
    end

    [ "", "abc", "2026-01", "26", "0000", "2024", [ "2026" ], { bad: "2026" } ].each do |value|
      it "returns 400 with an accessible error for invalid year #{value.inspect}" do
        get oshi_data_path, params: { year: value }
        expect(response).to have_http_status(:bad_request)
        expect(document.at_css("#data-filter-errors[role='alert']").text).to include("期間")
        expect(document.at_css("#activity-count")).to be_nil
        expect(document.at_css("#year")["aria-describedby"]).to eq("data-filter-errors")
      end
    end

    [ "abc", "0", "-1", "1.5", "01", [ "1" ], { bad: "1" } ].each do |value|
      it "returns 400 for malformed oshi #{value.inspect}" do
        get oshi_data_path, params: { oshi_id: value }
        expect(response).to have_http_status(:bad_request)
        expect(document.at_css("#data-filter-errors").text).to include("登録済み")
        expect(document.at_css("#activity-count")).to be_nil
      end
    end

    it "rejects another user's registration and unregistered approved oshis" do
      other_oshi = create(:oshi, :approved)
      create(:user_oshi, oshi: other_oshi)
      [ other_oshi, create(:oshi, :approved) ].each do |record|
        get oshi_data_path, params: { oshi_id: record.id }
        expect(response).to have_http_status(:bad_request)
        expect(document.at_css("main").text).not_to include(record.name)
      end
    end

    [ :approved, :pending, :rejected ].each do |status|
      it "allows an owned #{status} oshi even after its ended period" do
        record = create(:oshi, status)
        create(:user_oshi, user: user, oshi: record, started_period: "2023", ended_period: "2025/07")
        get oshi_data_path, params: { oshi_id: record.id }
        expect(response).to have_http_status(:ok)
        expect(document.at_css("#oshi-history").text).to eq("2023年から → 2025年7月まで")
      end
    end
  end
end
