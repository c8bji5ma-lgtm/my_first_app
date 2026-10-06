module OshiData
  class Summary
    attr_reader :date, :year, :oshi, :user_oshis

    def self.available_years(user:, date:)
      (user.activities.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM occurred_on)::integer")) + [ date.year ]).uniq.sort.reverse
    end

    def initialize(user:, date: Date.current, year: date.year, oshi: nil)
      @user = user
      @date = date
      @year = year
      @user_oshis = user.user_oshis.preload(:oshi).to_a
      @oshi = oshi && @user_oshis.find { |record| record.oshi_id == oshi.id }&.oshi
      raise ArgumentError, "Oshi must belong to the user's registered oshis" if oshi && !@oshi
    end

    def period_end
      year == date.year ? date : Date.new(year, 12, 31)
    end

    def month_count
      year == date.year ? date.month : 12
    end

    def activity_count
      @activity_count ||= activities.count
    end

    def activity_amount
      @activity_amount ||= expenditure_activities.sum(:amount)
    end

    # Recording a common expense still distinguishes a filtered view from all-nil amounts.
    def amount_recorded?
      @amount_recorded = activities.where.not(amount: nil).exists? if @amount_recorded.nil?
      @amount_recorded
    end

    def monthly_average
      (activity_amount.to_r / month_count).round if amount_recorded?
    end

    def common_amount
      @common_amount ||= activities.where(id: classified_activity_ids("COUNT(*) >= 2")).sum(:amount)
    end

    def previous_activity_count
      @previous_activity_count ||= begin
        last_day = year == date.year ? date.prev_year : Date.new(year - 1, 12, 31)
        activity_scope(Date.new(year - 1, 1, 1)..last_day).count
      end
    end

    def activity_change
      activity_count - previous_activity_count
    end

    def monthly_activities
      @monthly_activities ||= begin
        counts = activities.group(Arel.sql("EXTRACT(MONTH FROM occurred_on)::integer")).count
        (1..month_count).map { |month| { month: month, count: counts.fetch(month, 0) } }
      end
    end

    def categories
      @categories ||= begin
        counts = activities.group(:activity_type).count
        Activity::ACTIVITY_TYPES.filter_map do |category|
          count = counts.fetch(category, 0)
          next if count.zero?
          { name: category, count: count, percentage: (count.to_r * 100 / activity_count).round }
        end
      end
    end

    def per_oshi
      @per_oshi ||= begin
        counts = ActivityOshi.where(activity_id: activities.select(:id)).group(:oshi_id).count
        records = oshi ? user_oshis.select { |record| record.oshi_id == oshi.id } : user_oshis
        records.map { |record| { oshi: record.oshi, count: counts.fetch(record.oshi_id, 0) } }
          .sort_by { |row| [ -row[:count], row[:oshi].name, row[:oshi].id ] }
      end
    end

    def history
      record = oshi ? user_oshis.find { |item| item.oshi_id == oshi.id } : user_oshis.sole if oshi || user_oshis.one?
      return "推しが登録されていません" if user_oshis.empty?
      return "推しを選択すると推し歴を確認できます" unless record

      "#{format_period(record.started_period, 'から', '開始時期未設定')} → #{format_period(record.ended_period, 'まで', '現在')}"
    end

    def highlight_periods
      recent_start = period_end.beginning_of_month - 2.months
      previous_end = recent_start - 1.day
      { recent: recent_start..period_end, previous: (previous_end.beginning_of_month - 2.months)..previous_end }
    end

    def highlight
      return @highlight if defined?(@highlight)

      periods = highlight_periods
      recent = activity_scope(periods[:recent]).group(:activity_type).count
      previous = activity_scope(periods[:previous]).group(:activity_type).count
      recent_total = recent.values.sum
      previous_total = previous.values.sum
      @highlight = nil
      return if recent_total.zero? || previous_total.zero?

      changes = Activity::ACTIVITY_TYPES.map do |category|
        [ category, recent.fetch(category, 0).to_r / recent_total - previous.fetch(category, 0).to_r / previous_total ]
      end
      category, change = changes.max_by { |_, difference| difference }
      @highlight = "最近3か月は「#{category}」の割合が増えています。" if change.positive?
    end

    def monthly_fixed_cost
      @monthly_fixed_cost ||= @user.subscriptions.active_on(date).monthly.sum(:amount)
    end

    def yearly_fixed_cost
      @yearly_fixed_cost ||= @user.subscriptions.active_on(date).yearly.sum(:amount)
    end

    private

      def activities
        @activities ||= activity_scope(Date.new(year, 1, 1)..period_end)
      end

      def activity_scope(range)
        scope = @user.activities.where(occurred_on: range).where("occurred_on <= ?", date)
        if oshi
          scope = scope.where(id: ActivityOshi.where(oshi_id: oshi.id).select(:activity_id))
        end
        scope
      end

      def expenditure_activities
        oshi ? activities.where(id: classified_activity_ids("COUNT(*) = 1")) : activities
      end

      def classified_activity_ids(condition)
        ActivityOshi.where(activity_id: activities.select(:id)).group(:activity_id).having(condition).select(:activity_id)
      end

      def format_period(value, suffix, unset)
        return unset unless value

        year, month = value.split("/")
        "#{year}年#{"#{month.to_i}月" if month}#{suffix}"
      end
  end
end
