class OshiDataController < ApplicationController
  def show
    @reference_date = Date.current
    @years = OshiData::Summary.available_years(user: current_user, date: @reference_date)
    @user_oshis = current_user.user_oshis.preload(:oshi).to_a.sort_by { |record| [ record.oshi.name, record.oshi_id ] }
    @filter_errors = []
    @selected_year = @reference_date.year
    @selected_oshi = nil

    if params.key?(:year)
      value = params[:year]
      if value.is_a?(String) && value.match?(/\A[0-9]{4}\z/) && value.to_i.positive? && @years.include?(value.to_i)
        @selected_year = value.to_i
      else
        @filter_errors << "期間は選択肢にある年を選択してください。"
      end
    end

    value = params[:oshi_id]
    unless value.nil? || value == ""
      @selected_oshi = @user_oshis.find { |record| record.oshi_id == value.to_i }&.oshi if value.is_a?(String) && value.match?(/\A[1-9][0-9]*\z/)
      @filter_errors << "推しは登録済みの推しを選択してください。" unless @selected_oshi
    end

    if @filter_errors.any?
      render :show, status: :bad_request
    else
      @summary = OshiData::Summary.new(user: current_user, date: @reference_date, year: @selected_year, oshi: @selected_oshi)
    end
  end
end
