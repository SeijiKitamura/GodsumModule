module GodsumModules
  extend ActiveSupport::Concern
  module ClassMethods
    PARENT_COLUMNS = %w[number name].freeze
    SALEDATE       = "saledate".freeze
    SALE_YEAR      = "sale_year".freeze
    SALE_MONTH     = "sale_month".freeze
    SALE_DAY       = "sale_day".freeze
    SALE_CWEEK     = "sale_cweek".freeze
    SALE_WDAY      = "sale_wday".freeze
    SUM_COLUMNS    = %w[saleitem saleamt disitem disamt
                        dispitem dispamt customer cost
                        price stock].freeze
    @group_type = ""
    @option_group_columns  = []
    @option_order_columns  = []
    @model_ids      = []
    @kikan          = []

    def godsum(model_ids = [], kikan = [], group_type = :days, option_order_columns = [])
      # 引数をクラス変数にセット
      @model_ids = model_ids
      @kikan = kikan
      @group_type = group_type
      @option_group_columns = case group_type
                              when :years
                                %W[#{SALE_YEAR}]
                              when :months
                                %W[#{SALE_MONTH}]
                              when :weeks
                                %W[#{SALE_CWEEK}]
                              when :days
                                %W[#{SALE_MONTH} #{SALE_DAY}]
                              when :wdays
                                %W[#{SALE_CWEEK} #{SALE_WDAY}]
                              end
      @option_group_columns += %W[#{parent_table}_id]
      @option_order_columns = option_order_columns.presence || @option_group_columns

      # SQL実行
      select(select_sql)
        .from(from_sql)
        .joins(inner_join_sql)
        .group(last_group_sql)
        .order(last_order_sql)
    end

    # startdayからlastdayまでの期間売上を表示する
    def godsum_days(startday, lastday, *model_ids)
      model_ids = model_ids.flatten
      span = [startday - 1.year, lastday - 1.year, startday, lastday]
      godsum(model_ids, span, :days)
    end

    # 週別売上
    # ---------------------------------------------- #
    #                *** 警告 ***                    #
    # (前年同週が存在しない場合、正しい値が返らない) #
    # ---------------------------------------------- #
    def godsum_weeks(startday, lastday, *model_ids)
      model_ids = model_ids.flatten

      z_startday = if get_z_startday(startday)
                     get_z_startday(startday) + startday.wday.day
                   else
                     Time.zone.local(startday - 1.year, 12, 25)
                   end
      z_lastday = z_startday + (lastday - startday)
      godsum(model_ids,[z_startday, z_lastday, startday, lastday], :weeks)
    end

    # 月別売上
    def godsum_months(startday, lastday, *model_ids)
      model_ids = model_ids.flatten
      z_startday = startday - 1.year
      z_lastday = lastday - 1.year
      godsum(model_ids, [z_startday, z_lastday, startday, lastday],:months)
    end

    # 年別売上
    def godsum_years(startday, lastday, *model_ids)
      model_ids = model_ids.flatten
      z_startday = startday - 1.year
      z_lastday = lastday - 1.year
      godsum(model_ids, [z_startday, z_lastday, startday, lastday],:years)
    end

    private

    # 12/26-31の場合、nilが返る可能性がある
    def get_z_startday(saledate)
      z_startday = nil
      ((saledate - 1.year).beginning_of_year..(saledate - 1.year).end_of_year).each do |d|
        z_startday = d if d.cweek == saledate.cweek
      end
      z_startday
    end


    # 親テーブル名(定数的な扱い)
    def parent_table
      reflect_on_all_associations.first.name.to_s
    end

    # SELECT句のSQL文を発行。
    def select_sql
      set_select_columns.join(",")
    end

    # FROM句のSQL文を発行。
    def from_sql
      %W[(#{create_inner_table}) as t1].join(" ")
    end

    # INNER JOIN句のSQL文を発行。
    def inner_join_sql
      %W[inner join (#{create_inner_table}) as t2
         on #{set_base_inner_join_columns.join(' ')}
         #{set_last_inner_join_columns.join(' ')}].join(' ')
    end

    # GROUP句のSQL文を発行。
    def last_group_sql
      set_last_group_columns.join(',')
    end

    # ORDER句のSQL文を発行。
    def last_order_sql
      set_last_order_columns.join(',')
    end

    # 各種メソッドを使用してt1とt2のSQLを生成
    def create_inner_table
      %W[select
         #{set_base_select_columns.join(',')}
         from #{table_name}
         where
         #{set_base_where_columns.join(' ')}
         group by
         #{set_base_group_columns.join(',')}].join(' ')
    end

    # t1とt2のselect句を生成
    def set_base_select_columns
      ary1 = @option_group_columns.map do |column|
        "#{table_name}.#{column}"
      end
      ary2 = SUM_COLUMNS.map do |column|
        ["sum(case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then #{table_name}.#{column} else 0 end) as z_#{column}",
         "sum(case when #{table_name}.#{SALEDATE} between '#{@kikan[2]}' and '#{@kikan[3]}' then #{table_name}.#{column} else 0 end) as #{column}"]
      end.flatten
      ary3 = [(set_base_hiduke + %w[as hiduke]).join(" ")]
      ary1 + ary2 + ary3
    end

    # t1とt2のinner join用の列を作成
    def set_base_hiduke
      case @group_type
      when :wdays
        %W[case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then
           (#{table_name}.#{SALE_YEAR} + 1) * 1000 + #{table_name}.#{SALE_CWEEK} * 100 + #{table_name}.#{SALE_WDAY}
           else
           (#{table_name}.#{SALE_YEAR}) * 1000 + #{table_name}.#{SALE_CWEEK} * 100 + #{table_name}.#{SALE_WDAY}
           end]

      when :days
        %W[case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then
           (#{table_name}.#{SALE_YEAR} + 1) * 1000 + #{table_name}.#{SALE_MONTH} * 100 + #{table_name}.#{SALE_DAY}
           else
           (#{table_name}.#{SALE_YEAR}) * 1000 + #{table_name}.#{SALE_MONTH} * 100 + #{table_name}.#{SALE_DAY}
           end]
      when :weeks
        %W[case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then
           (#{table_name}.#{SALE_YEAR} + 1) * 100 + #{table_name}.#{SALE_CWEEK}
           else
           (#{table_name}.#{SALE_YEAR}) * 100 + #{table_name}.#{SALE_CWEEK}
           end]
      when :months
        %W[case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then
           (#{table_name}.#{SALE_YEAR} + 1) * 100 + #{table_name}.#{SALE_MONTH}
           else
           (#{table_name}.#{SALE_YEAR} * 100 + #{table_name}.#{SALE_MONTH})
           end]
      when :years
        %W[case when #{table_name}.#{SALEDATE} between '#{@kikan[0]}' and '#{@kikan[1]}' then
           #{table_name}.#{SALE_YEAR} + 1
           else
           #{table_name}.#{SALE_YEAR}
           end]
      end
    end

    # t1とt2のwhere句を生成
    def set_base_where_columns
      %W[#{table_name}.#{SALEDATE}
         between '#{@kikan[0]}' and '#{@kikan[1]}'
         and #{table_name}.#{parent_table}_id in (#{@model_ids.join(',')})
         or
         #{table_name}.#{SALEDATE}
         between '#{@kikan[2]}' and '#{@kikan[3]}'
         and #{table_name}.#{parent_table}_id in (#{@model_ids.join(',')})]
    end

    # t1とt2のgroup句を生成
    def set_base_group_columns
      ary1 = @option_group_columns.map do |column|
        "#{table_name}.#{column}"
      end
      ary2 = [set_base_hiduke.join(" ")]
      ary1 + ary2
    end

    # t1とt2のinner join句を生成
    def set_base_inner_join_columns
      ["t1.#{parent_table}_id = t2.#{parent_table}_id",
       "t1.hiduke >= t2.hiduke"].join(" and ").split
    end

    # t1とt3のinner join句を生成
    def set_last_inner_join_columns
      %W[inner join #{parent_table.pluralize} as t3 on
         t1.#{parent_table}_id = t3.id]
    end

    # t1,t2,t3を併せたテーブルのselect句を生成
    def set_select_columns
      ary1 = PARENT_COLUMNS.map do |column|
        "t3.#{column}"
      end
      ary2 = @option_group_columns.map do |column|
        "t1.#{column}"
      end
      ary3 = SUM_COLUMNS.map do |column|
        ["t1.#{column} as #{column}",
         "t1.z_#{column} as z_#{column}"]
      end.flatten
      ary4 = SUM_COLUMNS.map do |column|
        ["sum(t2.#{column}) as r_#{column}",
         "sum(t2.z_#{column}) as r_z_#{column}"]
      end.flatten
      ary1 + ary2 + ary3 + ary4
    end

    # t1,t2,t3を併せたテーブルのgroup句
    def set_last_group_columns
      ary1 = PARENT_COLUMNS.map do |column|
        "t3.#{column}"
      end
      ary2 = @option_group_columns.map do |column|
        "t1.#{column}"
      end
      ary3 = SUM_COLUMNS.map do |column|
        %W[t1.#{column}
           t1.z_#{column}]
      end.flatten
      ary1 + ary2 + ary3
    end

    # t1,t2,t3を併せたテーブルのorder句
    def set_last_order_columns
      @option_order_columns
    end
  end
end
