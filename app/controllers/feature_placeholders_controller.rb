class FeaturePlaceholdersController < ApplicationController
  FEATURES = {
    "data" => { title: "推し活データ", message: "推し活データの可視化機能は現在準備中です。", subscription_link: true },
    "profile" => { title: "プロフィール編集", message: "プロフィールの編集機能は現在準備中です。" }
  }.freeze

  def show
    @feature = FEATURES.fetch(request.path_parameters.fetch(:feature))
  end
end
