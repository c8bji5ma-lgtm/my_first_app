class FeaturePlaceholdersController < ApplicationController
  FEATURES = {
    "oshis" => { title: "推し一覧", message: "推し一覧の機能は現在準備中です。" },
    "activities" => { title: "活動記録一覧", message: "活動記録一覧の機能は現在準備中です。", record_link: true },
    "new_activity" => { title: "活動記録を登録", message: "活動記録の登録機能は現在準備中です。" },
    "data" => { title: "推し活データ", message: "推し活データの可視化機能は現在準備中です。" },
    "profile" => { title: "プロフィール編集", message: "プロフィールの編集機能は現在準備中です。" }
  }.freeze

  def show
    @feature = FEATURES.fetch(request.path_parameters.fetch(:feature))
  end
end
