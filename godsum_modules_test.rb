require "test_helper"

class GodsumModuleTest < ActiveSupport::TestCase
  # LineSaleにデータを挿入してテストしてく
  def setup
    @line = lines(:line_1)
    # Line追加
    @line_2 = @line.dept.lines.create(number: 2, name: "line_2")
  end

  test "godsum_years" do
    #  期待する値(@line)
    #  -------------------------------
    # |sale_year | z_saleamt | saleamt|
    # |----------|-----------|--------|
    # |2022      | nil       | 100    |
    # |2023      | 100       | 200    |
    # |2024      | 200       | 300    |
    #  -------------------------------
    sale_year = [2022, 2023, 2024]
    z_saleamt = [nil, 100, 200]
    saleamt = [100, 200, 300]

    set_years
    line_sales = Line.godsum_years("2022-08-01", "2024-08-01", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_year)

    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_year[idx].to_i, line_sale.sale_year

      if z_saleamt[idx].nil?
        assert_nil line_sale.z_saleamt
      else
        assert_equal z_saleamt[idx], line_sale.z_saleamt
      end

      assert_equal saleamt[idx], line_sale.saleamt
    end
  end

  test "godsum_months" do
    # 期待する値(@line)
    # sale_month | saleamt | r_saleamt |
    # --------------------------------
    #  6         | 100     |   100     |
    #  7         | 200     |   300     |
    #  8         | 300     |   600     |
    # ---------------------------------
    sale_month = [6, 7, 8]
    saleamt = [100, 200, 300]
    r_saleamt = [100, 300, 600]

    set_months
    line_sales = Line.godsum_months("2024-06-01", "2024-08-01", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_month)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_month[idx], line_sale.sale_month
      assert_equal saleamt[idx], line_sale.saleamt
      assert_equal r_saleamt[idx], line_sale.r_saleamt
    end
  end

  test "godsum_months z" do
    # 期待する値(@line)
    # sale_month | z_saleamt | z_r_saleamt |
    # -------------------------------------
    #  6         | 100       |   100       |
    #  7         | 200       |   300       |
    #  8         | 300       |   600       |
    # -------------------------------------
    sale_month = [6, 7, 8]
    z_saleamt = [100, 200, 300]
    z_r_saleamt = [100, 300, 600]

    set_months
    line_sales = Line.godsum_months("2024-06-01", "2024-08-01", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_month)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_month[idx], line_sale.sale_month
      assert_equal z_saleamt[idx], line_sale.z_saleamt
      assert_equal z_r_saleamt[idx], line_sale.z_r_saleamt
    end
  end

  test "godsum_days" do
    # 期待する値(@line)
    # sale_month | sale_day | saleamt | r_saleamt|
    # -------------------------------------------
    #     8      |    1     | 100     | 100      |
    #     8      |    2     | 100     | 200      |
    #     8      |    3     | 100     | 300      |
    # -------------------------------------------
    sale_days = [1, 2, 3]
    saleamt = 100
    r_saleamt = [100, 200, 300]

    set_days
    line_sales = Line.godsum_days("2024-08-01", "2024-08-03", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_month, :sale_day)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_days[idx], line_sale.sale_day
      assert_equal saleamt, line_sale.saleamt
      assert_equal r_saleamt[idx], line_sale.r_saleamt
    end
  end

  test "godsum_days z" do
    # 期待する値(@line)
    # sale_month | sale_day | z_saleamt | z_r_saleamt|
    # -----------------------------------------------
    #     8      |    1     | 100       | 100        |
    #     8      |    2     | 100       | 200        |
    #     8      |    3     | 100       | 300        |
    # -----------------------------------------------
    sale_days = [1, 2, 3]
    z_saleamt = 100
    z_r_saleamt = [100, 200, 300]

    set_days
    line_sales = Line.godsum_days("2024-08-01", "2024-08-03", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_month, :sale_day)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_days[idx], line_sale.sale_day
      assert_equal z_saleamt, line_sale.z_saleamt
      assert_equal z_r_saleamt[idx], line_sale.z_r_saleamt
    end
  end

  test "godsum_weeks" do
    # 期待する値(@line)
    # sale_cweek | saleamt | r_saleamt|
    # ---------------------------------
    #     30     | 100     | 100      |
    #     31     | 100     | 200      |
    #     32     | 100     | 300      |
    # ---------------------------------
    sale_cweeks = [30, 31, 32]
    saleamt = 100
    r_saleamt = [100, 200, 300]

    set_weeks
    line_sales = Line.godsum_weeks("2024-07-24", "2024-08-31", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_cweek)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_cweeks[idx], line_sale.sale_cweek
      assert_equal saleamt, line_sale.saleamt
      assert_equal r_saleamt[idx], line_sale.r_saleamt
    end
  end

  test "godsum_weeks z" do
    # 期待する値(@line)
    # sale_cweek | z_saleamt | z_r_saleamt|
    # ------------------------------------
    #     30     | 100       | 100        |
    #     31     | 100       | 200        |
    #     32     | 100       | 300        |
    # ------------------------------------
    sale_cweeks = [30, 31, 32]
    z_saleamt = 100
    z_r_saleamt = [100, 200, 300]

    set_weeks
    line_sales = Line.godsum_weeks("2024-07-24", "2024-08-31", model: LineSale)
                     .where(lines: { id: @line.id })
                     .order(:sale_cweek)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal sale_cweeks[idx], line_sale.sale_cweek
      assert_equal z_saleamt, line_sale.z_saleamt
      assert_equal z_r_saleamt[idx], line_sale.z_r_saleamt
    end
  end

  test "godsum_sub" do
    # 期待する値
    # line_id    | saleamt | z_saleamt|
    # ---------------------------------
    # @line.id   | 300     | 300      |
    # @line_2.id | 300     | 300      |
    # ---------------------------------
    lines = [@line, @line_2]
    saleamt = 300
    z_saleamt = 300

    set_days
    line_sales = Line.godsum_sub("2024-08-01", "2024-08-03", model: LineSale)
                     .where(lines: { id: [@line.id, @line_2.id] })
                     .order(:id)
    line_sales.each_with_index do |line_sale, idx|
      assert_equal lines[idx].id, line_sale.id
      assert_equal saleamt, line_sale.saleamt
      assert_equal z_saleamt, line_sale.z_saleamt
    end
  end

  test "godsum_grand" do
    # 期待する値
    # | saleamt | z_saleamt|
    # ----------------------
    # | 600     | 600      |
    # ----------------------
    saleamt = 600
    z_saleamt = 600

    set_days
    line_sales = Line.godsum_grand("2024-08-01", "2024-08-03", model: LineSale)
                     .where(lines: { id: [@line.id, @line_2.id] })
    line_sales.each do |line_sale|
      assert_equal saleamt, line_sale.saleamt
      assert_equal z_saleamt, line_sale.z_saleamt
    end
  end

  test "same_weekday_last_year" do
    lastday = Time.zone.today.end_of_year
    startday = (lastday - 10.years).beginning_of_year

    (startday..lastday).each do |saledate|
      d = LineSale.same_weekday_last_year(saledate)
      # assert_equal d.cweek, saledate.cweek
      assert_equal d.wday, saledate.wday
    end
  end

  private

  def set_years
    LineSale.destroy_all
    (2022..2024).each_with_index do |year, idx|
      saledate = Time.zone.local(year, 8, 1).to_date
      [@line, @line_2].each do |line|
        line.line_sales.create(
          saledate: saledate,
          saleitem: 0,
          saleamt: 100 * (idx + 1),
          sale_year: saledate.year,
          sale_month: saledate.month,
          sale_day: saledate.day,
          sale_cweek: saledate.cweek,
          sale_wday: saledate.wday
        )
      end
    end
  end

  def set_months
    LineSale.destroy_all
    (2023..2024).each do |year|
      (6..8).each_with_index do |month, idx|
        saledate = Time.zone.local(year, month, 1).to_date
        [@line, @line_2].each do |line|
          line.line_sales.create(
            saledate: saledate,
            saleitem: 0,
            saleamt: 100 * (idx + 1),
            sale_year: saledate.year,
            sale_month: saledate.month,
            sale_day: saledate.day,
            sale_cweek: saledate.cweek,
            sale_wday: saledate.wday
          )
        end
      end
    end
  end

  def set_days
    LineSale.destroy_all
    (2023..2024).each do |year|
      (1..3).each do |day|
        saledate = Time.zone.local(year, 8, day).to_date
        [@line, @line_2].each do |line|
          line.line_sales.create(
            saledate: saledate,
            saleitem: 0,
            saleamt: 100,
            sale_year: saledate.year,
            sale_month: saledate.month,
            sale_day: saledate.day,
            sale_cweek: saledate.cweek,
            sale_wday: saledate.wday
          )
        end
      end
    end
  end

  def set_weeks
    d = Time.zone.local(2024, 7, 24).to_date
    startday = d
    (0..2).each do |idx|
      saledate = startday + (idx * 7).days
      [@line, @line_2].each do |line|
        line.line_sales.create(
          saledate: saledate,
          saleitem: 0,
          saleamt: 100,
          sale_year: saledate.year,
          sale_month: saledate.month,
          sale_day: saledate.day,
          sale_cweek: saledate.cweek,
          sale_wday: saledate.wday
        )
      end
    end

    z_startday = startday.prev_year - startday.prev_year.wday + startday.wday
    (0..2).each do |idx|
      saledate = z_startday + (idx * 7).days
      [@line, @line_2].each do |line|
        line.line_sales.create(
          saledate: saledate,
          saleitem: 0,
          saleamt: 100,
          sale_year: saledate.year,
          sale_month: saledate.month,
          sale_day: saledate.day,
          sale_cweek: saledate.cweek,
          sale_wday: saledate.wday
        )
      end
    end
  end
end
