module GodsumModules
  extend ActiveSupport::Concern
  module ClassMethods
    SALEDATE       = "saledate".freeze
    SALE_YEAR      = "sale_year".freeze
    SALE_MONTH     = "sale_month".freeze
    SALE_DAY       = "sale_day".freeze
    SALE_CWEEK     = "sale_cweek".freeze
    SALE_WDAY      = "sale_wday".freeze
    SUM_COLUMNS    = %w[saleamt].freeze

    def godsum(sql, columns, var_columns)
      # 変換
      columns.each do |column|
        sql.gsub!(/\b#{column[0]}\b/, column[1])
      end

      var_columns.each do |column|
        sql.gsub!(%r{/\* #{column[0]} start \*/.*?/\* end \*/}, column[1])
      end

      # clean up
      sql.gsub!(%r{/\*.*?\*/}, "")
      sql = sql.split.join(" ")

      # 分割
      matches = /\Aselect (.*?) from (.*?) (left .*)\z/.match(sql)

      # SQL実行
      select(matches[1]).from(matches[2]).joins(matches[3])
    end

    # 年別売上前年比較(単一部門用)
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_years(startday, lastday, **options)
      # SQL取得
      sql = years_sql

      # 変数をセット
      child = has_many_table(options[:model])
      @sum_columns = options[:sum_columns] || SUM_COLUMNS

      # 定数変換テーブル
      columns = [["PARENT", table_name],
                 ["CHILD", child],
                 ["SALE_YEAR", SALE_YEAR],
                 ["SALEDATE", SALEDATE],
                 ["CHILD_ID", many_table_id],
                 ["STARTDAY", startday.to_s],
                 ["LASTDAY", lastday.to_s]]

      # 変数変換テーブル
      var_columns = [["master columns", master_columns],
                     ["FINAL_SUM_COLUMNS", year_t1_t2_columns],
                     ["SUM_COLUMNS", sum_columns(child)]]
      godsum(sql, columns, var_columns)
    end

    # 月別売上前年比較(単一部門用)
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_months(startday, lastday, **options)
      # SQL取得
      sql = months_sql

      # 変数をセット
      child = has_many_table(options[:model])
      @sum_columns = options[:sum_columns] || SUM_COLUMNS

      # 定数変換テーブル
      columns = [["PARENT", table_name],
                 ["CHILD", child],
                 ["SALE_YEAR", SALE_YEAR],
                 ["SALE_MONTH", SALE_MONTH],
                 ["SALEDATE", SALEDATE],
                 ["CHILD_ID", many_table_id],
                 ["STARTDAY", startday.to_s],
                 ["LASTDAY", lastday.to_s],
                 ["Z_STARTDAY", (startday.to_date - 1.year).to_s],
                 ["Z_LASTDAY", (lastday.to_date - 1.year).to_s]]

      # 変数変換テーブル
      var_columns = [["master columns", master_columns],
                     ["FINAL_SUM_COLUMNS", final_sum_columns],
                     ["Z_SUM_COLUMNS", z_sum_columns],
                     ["Z_R_SUM_COLUMNS", z_r_sum_columns],
                     ["SUM_COLUMNS", sum_columns(child)],
                     ["T6_SUM_COLUMNS", t6_sum_columns],
                     ["T7_SUM_COLUMNS", t7_sum_columns],
                     ["T1_GROUP_COLUMNS", t1_group_columns],
                     ["T2_GROUP_COLUMNS", t2_group_columns]]

      godsum(sql, columns, var_columns)
    end

    # 日別売上前年比較(単一部門用)
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_days(startday, lastday, **options)
      # 変数をセット
      child = has_many_table(options[:model])

      sql = days_sql

      # 定数変換テーブル
      columns = [["PARENT", table_name],
                 ["CHILD", child],
                 ["SALE_YEAR", SALE_YEAR],
                 ["SALE_MONTH", SALE_MONTH],
                 ["SALE_DAY", SALE_DAY],
                 ["SALEDATE", SALEDATE],
                 ["CHILD_ID", many_table_id],
                 ["STARTDAY", startday.to_s],
                 ["LASTDAY", lastday.to_s],
                 ["Z_STARTDAY", (startday.to_date - 1.year).to_s],
                 ["Z_LASTDAY", (lastday.to_date - 1.year).to_s]]
      # 変数変換テーブル
      var_columns = [["master columns", master_columns],
                     ["FINAL_SUM_COLUMNS", final_sum_columns],
                     ["Z_SUM_COLUMNS", z_sum_columns],
                     ["Z_R_SUM_COLUMNS", z_r_sum_columns],
                     ["SUM_COLUMNS", sum_columns(child)],
                     ["T6_SUM_COLUMNS", t6_sum_columns],
                     ["T7_SUM_COLUMNS", t7_sum_columns],
                     ["T1_GROUP_COLUMNS", t1_group_columns],
                     ["T2_GROUP_COLUMNS", t2_group_columns]]

      godsum(sql, columns, var_columns)
    end

    # 週別売上前年比較(単一部門用)
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_weeks(startday, lastday, **options)
      # SQL取得
      sql = weeks_sql

      # 変数をセット
      child = has_many_table(options[:model])
      @sum_columns = options[:sum_columns] || SUM_COLUMNS

      # 前年同曜日を取得
      z_startday = same_weekday_last_year(startday)
      z_lastday = same_weekday_last_year(lastday)

      # 定数変換テーブル
      columns = [["PARENT", table_name],
                 ["CHILD", child],
                 ["SALE_YEAR", SALE_YEAR],
                 ["SALEDATE", SALEDATE],
                 ["CHILD_ID", many_table_id],
                 ["STARTDAY", startday.to_s],
                 ["LASTDAY", lastday.to_s],
                 ["Z_STARTDAY", z_startday.to_s],
                 ["Z_LASTDAY", z_lastday.to_s]]

      # 変数変換テーブル
      var_columns = [["master columns", master_columns],
                     ["FINAL_SUM_COLUMNS", final_sum_columns],
                     ["Z_SUM_COLUMNS", z_sum_columns],
                     ["Z_R_SUM_COLUMNS", z_r_sum_columns],
                     ["SUM_COLUMNS", sum_columns(child)],
                     ["T6_SUM_COLUMNS", t6_sum_columns],
                     ["T7_SUM_COLUMNS", t7_sum_columns],
                     ["T1_GROUP_COLUMNS", t1_group_columns],
                     ["T2_GROUP_COLUMNS", t2_group_columns]]
      godsum(sql, columns, var_columns)
    end

    # カテゴリ別売上前年比較
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_sub(startday, lastday, **options)
      # SQL取得
      sql = sub_sql

      # 変数をセット
      child = has_many_table(options[:model])
      @sum_columns = options[:sum_columns] || SUM_COLUMNS

      # 定数変換テーブル
      columns = [["PARENT", table_name],
                 ["CHILD", child],
                 ["CHILD_ID", many_table_id],
                 ["STARTDAY", startday.to_s],
                 ["LASTDAY", lastday.to_s],
                 ["Z_STARTDAY", (startday.to_date - 1.year).to_s],
                 ["Z_LASTDAY", (lastday.to_date - 1.year).to_s]]

      # 変数変換テーブル
      var_columns = [["master columns", master_columns],
                     ["FINAL_SUM_COLUMNS", year_t1_t2_columns],
                     ["SUM_COLUMNS", sum_columns(child)]]
      godsum(sql, columns, var_columns)
    end

    # 合計売上前年比較
    # options
    #   model:       売上を管理してるテーブルを指定
    #   sum_columns: 集計したい列を配列で指定
    def godsum_grand(startday, lastday, **options)
      # 変数をセット
      child = has_many_table(options[:model])
      @sum_columns = options[:sum_columns] || SUM_COLUMNS

      select(grand_sum_columns(child, startday, lastday)).from(grand_from(child)).where(grand_where(child, startday, lastday))
    end

    # saledateが53週目の場合、正しく表示されない
    def same_weekday_last_year(saledate)
      saledate = saledate.to_date
      # 初期値をセット
      sameday = saledate.prev_year - saledate.prev_year.wday + saledate.wday

      # 前年年始から大みそかまで検索
      startday = saledate.prev_year.beginning_of_year
      lastday = startday.end_of_year
      (startday..lastday).each do |d|
        if d.cweek == saledate.cweek && d.wday == saledate.wday
          sameday = d
          break
        end
      end

      sameday
    end

    private

    # 売上データを格納しているテーブルを返す
    def has_many_table(model = nil)
      tables = reflect_on_all_associations(:has_many).map(&:name)
      model.nil? ? tables.first.to_s : model.to_s.pluralize.underscore
    end

    # 売上データを格納しているID列を返す
    def many_table_id
      "#{table_name.singularize}_id"
    end

    # 親テーブルの列すべてを返す
    def master_columns
      column_names.map do |column|
        "#{table_name}.#{column}"
      end.join(",")
    end

    def year_t1_columns
      @sum_columns.map do |column|
        "t1.#{column} as #{column}"
      end
    end

    def year_t2_columns
      @sum_columns.map do |column|
        "t2.#{column} as z_#{column}"
      end
    end

    def year_t1_t2_columns
      ([""] + year_t1_columns + year_t2_columns).join(",")
    end

    def sum_columns(child)
      ([""] + @sum_columns.map do |column|
        "sum(#{child}.#{column}) as #{column}"
      end).join(",")
    end

    def month_t1_columns
      # testが失敗する場合がある
      @sum_columns.map do |column|
        %W[t1.z_#{column} t1.z_r_#{column}]
      end.flatten
    end

    def month_t2_columns
      @sum_columns.map do |column|
        %W[t2.#{column} t2.r_#{column}]
      end.flatten
    end

    def final_sum_columns
      ([""] + month_t1_columns + month_t2_columns).join(",")
    end

    def z_sum_columns
      ([""] + @sum_columns.map do |column|
        "t4.#{column} as z_#{column}"
      end).join(",")
    end

    def z_r_sum_columns
      ([""] + @sum_columns.map do |column|
        "sum(t5.#{column}) as z_r_#{column}"
      end).join(",")
    end

    def t6_sum_columns
      ([""] + @sum_columns.map do |column|
        "t6.#{column} as #{column}"
      end).join(",")
    end

    def t7_sum_columns
      ([""] + @sum_columns.map do |column|
        "sum(t7.#{column}) as r_#{column}"
      end).join(",")
    end

    def t1_group_columns
      ([""] + @sum_columns.map do |column|
        "t4.#{column}"
      end).join(",")
    end

    def t2_group_columns
      ([""] + @sum_columns.map do |column|
        "t6.#{column}"
      end).join(",")
    end

    def grand_sum_columns(child, startday, lastday)
      @sum_columns.map do |column|
        ["sum(case when #{child}.#{SALEDATE} between '#{startday.to_date - 1.year}' and '#{lastday.to_date - 1.year}' then #{child}.#{column} else 0 end) as z_#{column}",
         "sum(case when #{child}.#{SALEDATE} between '#{startday.to_date - 1.year}' and '#{lastday.to_date - 1.year}' then #{child}.#{column} else 0 end) as #{column}"]
      end.join(",").squish
    end

    def grand_from(child)
      "#{table_name} inner join #{child} on #{table_name}.id = #{child}.#{many_table_id}"
    end

    def grand_where(child, startday, lastday)
      "#{child}.#{SALEDATE} between '#{startday.to_date - 1.year}' and '#{lastday.to_date - 1.year}' or #{child}.#{SALEDATE} between '#{startday}' and '#{lastday}'"
    end

    def years_sql
      <<-SQL.squish
        select
          /* master columns start */
          PARENT.id,
          PARENT.number,
          /* end */
          ,t1.SALE_YEAR
          ,t1.CHILD_ID
          /* FINAL_SUM_COLUMNS start */
          ,t1.saleamt as saleamt
          ,t2.saleamt as z_saleamt
          /* end */
        from (
          select
             CHILD.CHILD_ID
            ,CHILD.SALE_YEAR
            /* SUM_COLUMNS start */
            ,sum(CHILD.saleamt) as saleamt
            /* end */
          from
          CHILD
          where
            CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
          group by
             CHILD.SALE_YEAR
            ,CHILD.CHILD_ID
        ) as t1
        left outer join (
           select
              CHILD.CHILD_ID
             ,CHILD.SALE_YEAR
             ,CHILD.SALE_YEAR + 1 as hiduke
             /* SUM_COLUMNS start */
             ,sum(CHILD.saleamt) as saleamt
             /* end */
           from
           CHILD
           where
             CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
           group by
              CHILD.SALE_YEAR
             ,CHILD.CHILD_ID
        ) as t2 on
            t1.SALE_YEAR = t2.hiduke
        and t1.CHILD_ID = t2.CHILD_ID
        inner join PARENT on
        t1.CHILD_ID = PARENT.id
      SQL
    end

    def months_sql
      <<-SQL.squish
        /* 月別売上(単一部門用) */
        select
          /* master columns start */
           PARENT.number
          /* end */
          ,t1.SALE_MONTH
          /* FINAL_SUM_COLUMNS start */
          ,t1.z_saleamt
          ,t1.z_r_saleamt
          ,t2.saleamt
          ,t2.r_saleamt
          /* end */
        from (
          /* 前年用テーブル*/
          select
             t3.SALE_MONTH
            ,t3.CHILD_ID
            /* Z_SUM_COLUMNS start */
            ,t4.saleamt as z_saleamt
            /* end */
            /* Z_R_SUM_COLUMNS start */
            ,sum(t5.saleamt) as z_r_saleamt
            /* end */
          from (
            /* 日付テーブル*/
            select
               CHILD.SALE_MONTH
              ,CHILD.CHILD_ID
            from
            CHILD
            where
                 CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              or CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_MONTH
              ,CHILD.CHILD_ID
            ) as t3 left outer join (
              /* 前年売上テーブル */
              select
                 CHILD.SALE_MONTH
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_MONTH
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100
            ) as t4 on
                  t3.SALE_MONTH = t4.SALE_MONTH
              and t3.CHILD_ID = t4.CHILD_ID
            left outer join (
              /* 前年累計用 */
              select
                 CHILD.SALE_MONTH
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_MONTH
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100
            ) as t5 on
                  t4.hiduke >= t5.hiduke
              and t4.CHILD_ID = t5.CHILD_ID
          group by
             t3.SALE_MONTH
            ,t3.CHILD_ID
            /* T1_GROUP_COLUMNS start */
            ,t4.saleamt
            /* end */
        ) as t1
        left outer join (
          /* 今年売上テーブル(累計込み) */
          select
             t6.SALE_MONTH
            ,t6.CHILD_ID
            /* T6_SUM_COLUMNS start */
            ,t6.saleamt
            /* end */
            /* T7_SUM_COLUMNS start */
            ,sum(t7.saleamt) as r_saleamt
            /* end */
          from (
            /* 今年売上テーブル */
            select
               CHILD.SALE_MONTH
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 as hiduke
              /* SUM_COLUMNS start */
              ,sum(saleamt) as saleamt
              /* end */
            from
            CHILD
            where
              CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_MONTH
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100
           ) as t6
           left outer join (
             /* 今年累計用テーブル */
             select
                CHILD.SALE_MONTH
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 as hiduke
               /* SUM_COLUMNS start */
               ,sum(saleamt) as saleamt
               /* end */
             from
             CHILD
             where
               CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
             group by
                CHILD.SALE_MONTH
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100
           ) as t7 on
                 t6.hiduke >= t7.hiduke
             and t6.CHILD_ID = t7.CHILD_ID
          group by
             t6.SALE_MONTH
            ,t6.CHILD_ID
            /* T2_GROUP_COLUMNS start */
            ,t6.saleamt
            /* end */
        ) as t2 on
              t1.SALE_MONTH = t2.SALE_MONTH
          and t1.CHILD_ID = t2.CHILD_ID
        inner join PARENT on
          t1.CHILD_ID = PARENT.id
      SQL
    end

    def days_sql
      <<-SQL.squish
        /* 日別売上(単一部門用） */
        select
          /* master columns start */
           PARENT.number
          /* end */
          ,t1.SALE_MONTH
          ,t1.SALE_DAY
          /* FINAL_SUM_COLUMNS start */
          ,t1.z_saleamt
          ,t1.z_r_saleamt
          ,t2.saleamt
          ,t2.r_saleamt
          /* end */
        from (
          /* 前年用テーブル*/
          select
             t3.SALE_MONTH
            ,t3.SALE_DAY
            ,t3.CHILD_ID
            /* Z_SUM_COLUMNS start */
            ,t4.saleamt as z_saleamt
            /* end */
            /* Z_R_SUM_COLUMNS start */
            ,sum(t5.saleamt) as z_r_saleamt
            /* end */
          from (
            /* 日付テーブル*/
            select
               CHILD.SALE_MONTH
              ,CHILD.SALE_DAY
              ,CHILD.CHILD_ID
            from
            CHILD
            where
                 CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              or CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_MONTH
              ,CHILD.SALE_DAY
              ,CHILD.CHILD_ID
            /* t3 end　*/
            ) as t3 left outer join (
              /* 前年売上テーブル */
              select
                /* select_t4 */
                 CHILD.SALE_MONTH
                ,CHILD.SALE_DAY
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_MONTH
                ,CHILD.SALE_DAY
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY
            ) as t4 on
                  t3.SALE_MONTH = t4.SALE_MONTH
              and t3.SALE_DAY = t4.SALE_DAY
              and t3.CHILD_ID = t4.CHILD_ID
            left outer join (
              /* 前年累計用 */
              select
                 CHILD.SALE_MONTH
                ,CHILD.SALE_DAY
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_MONTH
                ,CHILD.SALE_DAY
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY
            ) as t5 on
                  t4.hiduke >= t5.hiduke
              and t4.CHILD_ID = t5.CHILD_ID
          group by
             t3.SALE_MONTH
            ,t3.SALE_DAY
            ,t3.CHILD_ID
            /* T1_GROUP_COLUMNS start */
            ,t4.saleamt
            /* end */
        ) as t1
        left outer join (
          /* 今年売上テーブル(累計込み) */
          select
             t6.SALE_MONTH
            ,t6.SALE_DAY
            ,t6.CHILD_ID
            /* T6_SUM_COLUMNS start */
            ,t6.saleamt
            /* end */
            /* T7_SUM_COLUMNS start */
            ,sum(t7.saleamt) as r_saleamt
            /* end */
          from (
            /* 今年売上テーブル */
            select
               CHILD.SALE_MONTH
              ,CHILD.SALE_DAY
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY as hiduke
              /* SUM_COLUMNS start */
              ,sum(saleamt) as saleamt
              /* end */
            from CHILD
            where
              CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_MONTH
              ,CHILD.SALE_DAY
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY
           ) as t6
           left outer join (
             /* 今年累計用テーブル */
             select
                CHILD.SALE_MONTH
               ,CHILD.SALE_DAY
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY as hiduke
              /* SUM_COLUMNS start */
              ,sum(saleamt) as saleamt
              /* end */
             from
             CHILD
             where
               CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
             group by
                CHILD.SALE_MONTH
               ,CHILD.SALE_DAY
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_MONTH * 100 + CHILD.SALE_DAY
           ) as t7 on
                 t6.hiduke >= t7.hiduke
             and t6.CHILD_ID = t7.CHILD_ID
          group by
             t6.SALE_MONTH
            ,t6.SALE_DAY
            ,t6.CHILD_ID
            /* T2_GROUP_COLUMNS start */
            ,t6.saleamt
            /* end */
        ) as t2 on
          /* left_outer_t1_t2 */
              t1.SALE_MONTH = t2.SALE_MONTH
          and t1.SALE_DAY = t2.SALE_DAY
          and t1.CHILD_ID = t2.CHILD_ID
        inner join PARENT on
          t1.CHILD_ID = PARENT.id
      SQL
    end

    def weeks_sql
      <<-SQL.squish
        /* 週別売上結果(単一部門用) */
        select
          /* master columns start */
           PARENT.number
          /* end */
          ,t1.SALE_CWEEK
          /* FINAL_SUM_COLUMNS start */
          ,t1.z_saleamt
          ,t1.z_r_saleamt
          ,t2.saleamt
          ,t2.r_saleamt
          /* end */
        from (
          /* 前年用テーブル*/
          select
             t3.SALE_CWEEK
            ,t3.CHILD_ID
            /* Z_SUM_COLUMNS start */
            ,t4.saleamt as z_saleamt
            /* end */
            /* Z_R_SUM_COLUMNS start */
            ,sum(t5.saleamt) as z_r_saleamt
            /* end */
          from (
            /* 日付テーブル*/
            select
               CHILD.SALE_CWEEK
              ,CHILD.CHILD_ID
            from
            CHILD
            where
                 CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              or CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_CWEEK
              ,CHILD.CHILD_ID
            ) as t3 left outer join (
              /* 前年売上テーブル */
              select
                 CHILD.SALE_CWEEK
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100 as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_CWEEK
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100
            ) as t4 on
                  t3.SALE_CWEEK = t4.SALE_CWEEK
              and t3.CHILD_ID = t4.CHILD_ID
            left outer join (
              /* 前年累計用 */
              select
                 CHILD.SALE_CWEEK
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100 as hiduke
                /* SUM_COLUMNS start */
                ,sum(saleamt) as saleamt
                /* end */
              from
              CHILD
              where
                CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
              group by
                 CHILD.SALE_CWEEK
                ,CHILD.CHILD_ID
                ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100
            ) as t5 on
                  t4.hiduke >= t5.hiduke
              and t4.CHILD_ID = t5.CHILD_ID
          group by
             t3.SALE_CWEEK
            ,t3.CHILD_ID
            /* T1_GROUP_COLUMNS start */
            ,t4.saleamt
            /* end */
        ) as t1
        left outer join (
          /* 今年売上テーブル(累計込み) */
          select
             t6.SALE_CWEEK
            ,t6.CHILD_ID
            /* T6_SUM_COLUMNS start */
            ,t6.saleamt
            /* end */
            /* T7_SUM_COLUMNS start */
            ,sum(t7.saleamt) as r_saleamt
            /* end */
          from (
            /* 今年売上テーブル */
            select
               CHILD.SALE_CWEEK
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100 as hiduke
              /* SUM_COLUMNS start */
              ,sum(saleamt) as saleamt
              /* end */
            from
            CHILD
            where
              CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
            group by
               CHILD.SALE_CWEEK
              ,CHILD.CHILD_ID
              ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100
           ) as t6
           left outer join (
             /* 今年累計用テーブル */
             select
                CHILD.SALE_CWEEK
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100 as hiduke
               /* SUM_COLUMNS start */
               ,sum(saleamt) as saleamt
               /* end */
             from
             CHILD
             where
               CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
             group by
                CHILD.SALE_CWEEK
               ,CHILD.CHILD_ID
               ,CHILD.SALE_YEAR * 10000 + CHILD.SALE_CWEEK * 100
           ) as t7 on
                 t6.hiduke >= t7.hiduke
             and t6.CHILD_ID = t7.CHILD_ID
          group by
             t6.SALE_CWEEK
            ,t6.CHILD_ID
            /* T2_GROUP_COLUMNS start */
            ,t6.saleamt
            /* end */
        ) as t2 on
              t1.SALE_CWEEK = t2.SALE_CWEEK
          and t1.CHILD_ID = t2.CHILD_ID
        inner join PARENT on
          t1.CHILD_ID = PARENT.id
      SQL
    end

    def sub_sql
      <<-SQL.squish
        /* 部門別期間合計(複数部門用) */
        select
          /* master columns start */
           PARENT.number
          /* end */
          /* FINAL_SUM_COLUMNS start */
          ,t1.saleamt as saleamt
          ,t2.saleamt as z_saleamt
          /* end */
        from
        PARENT
        left outer join (
          select
            CHILD.CHILD_ID
            /* SUM_COLUMNS start */
            ,sum(saleamt) as saleamt
            /* end */
          from
          CHILD
          where
            CHILD.SALEDATE between 'STARTDAY' and 'LASTDAY'
          group by
            CHILD.CHILD_ID
        ) as t1 on
        PARENT.id = t1.CHILD_ID
        left outer join (
          select
            CHILD.CHILD_ID
            /* SUM_COLUMNS start */
            ,sum(saleamt) as saleamt
            /* end */
          from
          CHILD
          where
            CHILD.SALEDATE between 'Z_STARTDAY' and 'Z_LASTDAY'
          group by
            CHILD.CHILD_ID
        ) as t2 on
        PARENT.id = t2.CHILD_ID
      SQL
    end
  end
end
