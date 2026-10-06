require "rails_helper"

RSpec.describe "Top and home pages", type: :request do
  let(:user) { create(:user) }

  def document
    Nokogiri::HTML(response.body)
  end

  it "shows the public top with the service concept and authentication links" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(document.at_css("html")["lang"]).to eq("ja")
    expect(document.at_css("title").text).to eq("トップ | OshiLog")
    expect(document.at_css("main h1").text).to eq("OshiLog")
    expect(document.at_css("main").text).to include("記録する・振り返る・可視化する")
    expect(document.css("main h2").map(&:text)).to eq(%w[記録 振り返り 可視化])
    expect(document.at_css("main a[href='#{new_user_session_path}']").text).to eq("ログイン")
    expect(document.at_css("main a[href='#{new_user_registration_path}']").text).to eq("新規登録")
    expect(document.css("nav a").map(&:text)).to eq(%w[ログイン 新規登録])
    expect(document.at_css("nav a[href='#{oshis_path}']")).to be_nil
    expect(document.at_css("main").text).not_to include("今月の推し活", "18,400", "CANDY TUNE")
  end

  it "requires authentication for the direct home URL" do
    get home_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "requires authentication for my page" do
    get my_page_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "when signed in" do
    before do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
    end

    it "renders home at root without another redirect or sample data" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(document.at_css("title").text).to eq("ホーム | OshiLog")
      expect(document.at_css("main h1").text).to eq("ホーム")
      expect(document.css("main h2").map(&:text)).to eq(
        [ "今月の推し活", "推し活の積み重ね", "最近の記録", "思い出を振り返る", "今日の気づき" ]
      )
      expect(document.css("main section").map { |section| section.text.include?("準備中") }).to all(be(true))
      expect(document.at_css("main").text).not_to include("18,400", "CANDY TUNE", "活動 5回")
      expect(document.css("nav a").map(&:text)).to eq(%w[トップ 推し一覧 活動記録一覧 マイページ])
      expect(document.at_css("nav button").text).to eq("ログアウト")
      expect(document.at_css("nav a[href='#{new_user_session_path}']")).to be_nil
      expect(document.at_css("nav a[href='#{new_user_registration_path}']")).to be_nil
    end

    it "renders the same home content at the direct home URL" do
      get root_path
      root_content = document.at_css("main").to_html

      get home_path

      expect(response).to have_http_status(:ok)
      expect(document.at_css("main").to_html).to eq(root_content)
    end

    it "links from my page to oshi data and profile editing without a form" do
      get my_page_path

      expect(response).to have_http_status(:ok)
      expect(document.at_css("main h1").text).to eq("マイページ")
      expect(document.at_css("main a[href='#{oshi_data_path}']").text).to eq("推し活データを見る")
      expect(document.at_css("main a[href='#{edit_profile_path}']").text).to eq("プロフィール編集")
      expect(document.css("main form")).to be_empty
    end
  end
end
