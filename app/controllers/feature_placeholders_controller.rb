class FeaturePlaceholdersController < ApplicationController
  FEATURES = {
    "profile" => { title: "プロフィール編集", message: "プロフィールの編集機能は現在準備中です。" }
  }.freeze

  def show
    @feature = FEATURES.fetch(request.path_parameters.fetch(:feature))
  end
end
