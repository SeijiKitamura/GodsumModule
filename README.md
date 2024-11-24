# GodsumModule

| 月 | 日 | 売上 | 累計売上 | 前年売上 | 前年累計 |
|---|---|---|---|---|---|
| 4 | 1 | 100 | **100** | **50** | **50** |
| 4 | 2 | 120 | **220** | **80** | **130** |
| 4 | 3 | 130 | **350** | **90** | **220** |

**太字** 部分を簡単に集計できるActiveRecord用Moduleです。

クラスメソッドgodsumを使用することで今年のデータはもちろん、
前年や累計も簡単に集計できます。
集計単位も「年、月、週、日」の4つから選択可能です。

## DBテーブルと列について
マスタ情報を管理している親テーブルと売上情報を管理している子テーブルが必要です。

**Store（親テーブル)**

親テーブルには名前や店舗番号などの属性が保存されています。
| | 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|★| number | integer | 店番号 | 
|| name | string | 店名 | 
|| ・・・ | ・・・ | ・・・ |
|| ・・・ | ・・・ | ・・・ |

★-> 必須列

**Sale（子テーブル)**

子テーブルには売上データが格納されます。
|| 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|★| store_id | integer | 店ID |
|★| saledate| date | 日付 |
|★| saleamt | integer | 売上 | 
|| ・・・ | ・・・ | ・・・ |
|| ・・・ | ・・・ | ・・・ |
|★| sale_year | integer | 西暦 |
|★| sale_month | integer | 月 |
|★| sale_day | integer | 日 |
|★| sale_cweek | integer | 週数 |
|★| sale_wday | integer | 曜日  |

★-> 必須列

## Modelについて
上記テーブルのModelは以下の通りとなります。

**Store(親モデル）**
```ruby
class Store < Activerecord
  has_many :sales
end
```

**Sale(子モデル）**
```ruby
class Sale< Activerecord
  include GodsumModules
  belongs_to :store
  validates :saledate, presence: true
　before_save :set_date 
  ・・・・
　・・・・
  private
  # saledate列に入った値を使用して各列を更新する
  def set_date
    update(sale_year: saledate.year,
           sale_month: saledate.month,
           sale_day: saledate.day,
           sale_cweek: saledate.cweek,
           sale_wday: saledate.wday)
  end
end
```

## インストール
app/model/concernsにgodsum_modules.rbを配置してください。
その後、データを管理しているmodelに以下のコードを記述します。

```ruby
class Sale < Activerecord
  include GodsumModules
  belongs_to :store
  ・・・・
　・・・・
end
```

## 使い方
子モデルにクラスメソッド(godsum\_years,godsum\_months,godsum\_weeks,godsum\_days)が追加されます。
これらを使用してデータを集計します。

## 戻り値
.where などで呼び出したときと同じようなデータが返ってきます。
指定した集計列に加えてz\_、r\_、r\_z\_が先頭に付加された列名が追加されます。
それぞれの意味は以下の通りです。

| 接頭辞 | 意味 | 例 ||
|---|---|---|---|
| 無印 | 今年 | saleamt | 今年売上 |
| z\_ | 前年 | z\_saleamt | 前年売上 |
| r\_ | 今年累計| r\_saleamt | 今年累計売上 |
| r\_z\_ | 前年累計| r\_z\_saleamt | 前年累計売上 |

## 使用できるメソッド
4つのメソッドが追加されます。以下にそれぞれの使い方を説明します。

## godsum\_years
年別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定し、model\_idsに親テーブルのidを指定するとmodel\_id、年でグループ化された値の合計を取り出すことができます。

```ruby
Model.godsum_years(startday, lastday, *model_ids, **options)
```

**引数**

| 引数 | 省略 | 説明 |
|---|---|---|
| startday | 不可 | 集計する開始日を入力します。 |
| lastday  | 不可 | 集計する終了日を入力します。 |
| model\_ids | 不可 | 集計するIDを指定します。（複数可)|
| options[:total] | 可 | false or true |

**options**

- options[total: false] 年、model\_idsでグループ化した値の合計を表示します。(default)
- options[total: true] 年でグループ化した値の合計を表示します。

total: falseとtotal:trueの違いをSQLで示すと以下の通りとなります。

```
option[total: false]  | option[total: true]
select                | select
  sale_id             |   sale_year
 ,sale_year           |  ,sum(saleamt)
 ,sum(saleamt)        | from sales
from sales            | group by
group by              |   sale_year
  sale_id             |
 ,sale_year           |
```

**戻り値**

ActiveRecord\_Relationが返ります。

列名は以下の通りです。

| 列名 | 説明 |
| --- | --- |
| sale\_year | 年 |
| (model)\_id | 親モデルのid |
| saleamt | 期間売上 |
| z\_saleamt | 期間前年売上 |
| r\_saleamt | 期間累計売上 |
| r\_z\_saleamt | 期間累計前年売上 |

**例1 1店舗の売上合計を求める**

Store(親テーブル)に以下のデータが入っています。

| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store\_1| ・・・ |

Sale(子テーブル）に以下のデータが入っています。

| id | store\_id | saledate | saleamt | ・・・ | 
|---|---|---|---|---|
| 124 | 1 | 2022-01-01 | 100 | ・・・ |
| 125 | 1 | 2023-01-01 | 200 | ・・・ |
| 126 | 1 | 2024-01-01 | 300 | ・・・ |

**実行:** 

```ruby
@store = Store.find(params[:id])
@sales = Sale.godsum_years("2022-01-31", "2024-12-31", @store.id)
```

**結果:** 

store\_id、年でグループ化したsaleamtが集計されます。

| store\_id |sale\_year | saleamt | r\_saleamt | z\_saleamt | r\_z\_saleamt| number | name |・・・ |
| --- | --- | --- | --- | --- | --- |--- | --- |--- |
| 1 | 2022 | 100 | 100 | | | 1 | store 1 | ・・・|
| 1 | 2023 | 200 | 300 | 100 | 100 | 1 | store 1 | ・・・|
| 1 | 2024 | 300 | 600 | 200 | 300 | 1 | store 1 |  ・・・|


**例2 全店舗の売上合計を求める**

Store(親テーブル)に以下のデータが入っています。

| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store\_1| ・・・ |
| 1 | 2 | store\_2| ・・・ |

Sale(子テーブル）に以下のデータが入っています。

| id | store\_id | saledate | saleamt | ・・・ | 
|---|---|---|---|---|
| 124 | 1 | 2022-01-01 | 100 | ・・・ |
| 125 | 1 | 2023-01-01 | 200 | ・・・ |
| 126 | 1 | 2024-01-01 | 300 | ・・・ |
| 124 | 2 | 2022-01-01 | 400 | ・・・ |
| 125 | 2 | 2023-01-01 | 500 | ・・・ |
| 126 | 2 | 2024-01-01 | 600 | ・・・ |

**実行:** 

```ruby
@stores = Store.all
@sales = Sale.godsum_years("2022-01-31", "2024-12-31", @stores.ids, total: true)
```

**結果:** 

年でグループ化したsaleamtが集計されます。

| sale_year | saleamt | r_saleamt | z_saleamt | r_z_saleamt|
| --- | --- | --- | --- | --- |
| 2022 | 500 | 500 | | |
| 2023 | 700 | 1200 | 500 | 500 |
| 2024 | 900 | 2100 | 700 | 1200 

## godsum\_months
月別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定し、model\_idsに親テーブルのidを指定するとmodel\_id、月でグループ化された値の合計を取り出すことができます。

```ruby
Model.godsum_months(startday, lastday, *model_ids, **options)
```

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model\_ids | 集計するIDを指定します。（複数可)|
| options[:total] | 可 | false or true |

**options**

- options[total: false] 月、model\_idsでグループ化した値の合計を表示します。(default)
- options[total: true] 月でグループ化した値の合計を表示します。

**戻り値**

ActiveRecord\_Relationが返ります。

列名は以下の通りです。

| 列名 | 説明 |
| --- | --- |
| sale_month | 年 |
| (model)\_id | 親モデルのid |
| saleamt | 期間売上 |
| z\_saleamt | 期間前年売上 |
| r\_saleamt | 期間累計売上 |
| r\_z\_saleamt | 期間累計前年売上 |

**注意事項**

- startdayとlastdayの間隔は1年未満にしてください。
  - 1年以上を指定してもエラーにはなりません。
  - ロジック上、正しい値は表示されません。

**例1 1店舗の売上合計を求める**

Store(親テーブル)に以下のデータが入っています。

| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store\_1| ・・・ |

Sale(子テーブル）に以下のデータが入っています。

| id | store\_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 1 | 2023-06-01 | 200 | ・・・ |
| 102 | 1 | 2023-07-01 | 300 | ・・・ |
| 124 | 1 | 2024-05-01 | 400 | ・・・ |
| 125 | 1 | 2024-06-01 | 500 | ・・・ |
| 126 | 1 | 2024-07-01 | 600 | ・・・ |

**実行:** 

```ruby
@store = Store.find(params[:id])
@sales = Sale.godsum_months("2024-05-01","2024-7-31", @store.id)
```

**結果:** 

store\_id、月でグループ化したsaleamtが集計されます。

| store\_id | sale\_month | saleamt | r\_sale\_amt| z\_saleamt  | r\_z\_saleamt | ・・・ |
| --- | --- | --- | --- | --- | --- |--- |
| 1 | 5 | 400 | 400 | 100 | 100 | ・・・ |
| 1 | 6 | 500 | 900 | 200 | 300 | ・・・ |
| 1 | 7 | 600 | 1500 |300 | 600 | ・・・ |

**例2 全店舗の売上合計を求める**

全店舗合計の月別売上を求める場合は以下のコマンドを入力します。

**実行:** 

```ruby
@stores = Store.all
@sales = Sale.godsum_months("2024-05-01", "2024-07-31", @stores.ids, total: true)
```

**結果:** 

月でグループ化したsaleamtが集計されます。

| sale\_month | saleamt | r\_sale\_amt| z\_saleamt  | r\_z\_saleamt | ・・・ |
|---|---|---|---|---|---|
| 5 | 400 | 400 | 100 | 100 | ・・・ |
| 6 | 500 | 900 | 200 | 300 | ・・・ |
| 7 | 600 | 1500 |300 | 600 | ・・・ |

## godsum\_days
日別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定し、model\_idsに親テーブルのidを指定するとmodel\_id、月、日でグループ化された値の合計を取り出すことができます。

```ruby
Model.godsum_days(startday, lastday, *model_ids, **options)
```

| 引数 | 省略 | 説明 |
| --- | --- |
| startday | 不可 | 集計する開始日を入力します。 |
| lastday  | 不可 | 集計する終了日を入力します。 |
| model\_ids | 不可 | 集計するIDを指定します。（複数可)|
| options[:total] | 可 | false or true |

**options**

- options[total: false] 月、日、model\_idsでグループ化した値の合計を表示します。(default)
- options[total: true] 月、日でグループ化した値の合計を表示します。

**戻り値**

ActiveRecord\_Relationが返ります。

列名は以下の通りです。

| 列名 | 説明 |
| --- | --- |
| sale_month | 月 |
| sale_day | 日 |
| (model)\_id | 親モデルのid |
| saleamt | 期間売上 |
| z\_saleamt | 期間前年売上 |
| r\_saleamt | 期間累計売上 |
| r\_z\_saleamt | 期間累計前年売上 |

**注意事項**

- startdayとlastdayの間隔は1年未満にしてください。
  - 1年以上を指定してもエラーにはなりません。
  - ロジック上、正しい値は表示されません。

**例1 1店舗の売上合計を求める**

Sale(子テーブル）に以下のデータが入っています。
| id | store\_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 1 | 2023-05-02 | 200 | ・・・ |
| 102 | 1 | 2023-05-03 | 300 | ・・・ |
| 124 | 1 | 2024-05-01 | 400 | ・・・ |
| 125 | 1 | 2024-05-02 | 500 | ・・・ |
| 126 | 1 | 2024-05-03 | 600 | ・・・ |

**実行:** 

```ruby
@store = Store.first
@sales = Sale.godsum_days("2024-05-01", "2024-05-03", @store.id)
```

**結果:** 

store\_id、月、日でグループ化したsaleamtが集計されます。

|store\_id| sale\_month | sale\_day | saleamt | z\_saleamt | r\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|---|---|
| 1 | 5 | 1 | 400 | 400 | 100 | 100 |
| 1 | 5 | 2 | 500 | 900 | 200 | 300 |
| 1 | 5 | 3 | 600 | 1500 | 300 | 600 |

**例2 全店舗の売上合計を求める**
全店舗合計の日別売上を求める場合は以下のコマンドを入力します。

```ruby
@stores = Store.all
@sales = Sale.godsum_days("2024-05-01", "2024-05-03", @stores.ids, total: true)
```

**結果:** 

月、日でグループ化したsaleamtが集計されます。

| sale\_month | sale\_day | saleamt | z\_saleamt | r\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|---|
| 5 | 1 | xxx | xxx | xxx | xxx |
| 5 | 2 | xxx | xxx | xxx | xxx |
| 5 | 3 | xxx | xxx | xxx | xxx |

## godsum\_weeks
週別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定し、model_idsに親テーブルのidを指定するとmodel_id、週でグループ化された値の合計を取り出すことができます。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model\_ids | 集計するIDを指定します。（複数可)|
| options[:total] | 可 | false or true |

**options**

- options[total: false] 週、model\_idsでグループ化した値の合計を表示します。(default)
- options[total: true] 週でグループ化した値の合計を表示します。

**戻り値**

ActiveRecord\_Relationが返ります。

列名は以下の通りです。

| 列名 | 説明 |
| --- | --- |
| sale\_cweek | 週 |
| (model)\_id | 親モデルのid |
| saleamt | 期間売上 |
| z\_saleamt | 期間前年売上 |
| r\_saleamt | 期間累計売上 |
| r\_z\_saleamt | 期間累計前年売上 |

**注意事項**

- startdayとlastdayの間隔は1年未満にしてください。
  - 1年以上を指定してもエラーにはなりません。
  - ロジック上、正しい値は表示されません。
- 年末に正しい値が表示されない可能性がある
  - 7年に一度前年の週数が存在しない場合があります。

**例1 1店舗の売上合計を求める**

**実行:** 

```ruby
@store = Store.find(params[:id])
@sales = Sale.godsum_weeks("2024-05-01", "2024-05-08", @store.id)
```

**結果:** 

store\_id、週でグループ化したsaleamtが集計されます。

| store\_id | sale\_cweek | saleamt | z\_saleamt | r\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|---|
| 1 | 18 | ・・・ | ・・・ | ・・・ | ・・・ |


**例2 全店舗の売上合計を求める**

**実行:** 

```ruby
@store = Store.all
@sales = Sale.godsum\_weeks("2024-05-01", "2024-05-08", @stores.ids)
```

**結果:** 

週でグループ化したsaleamtが集計されます。

| sale\_cweek | saleamt | z\_saleamt | r\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|
| 18 | ・・・ | ・・・ | ・・・ | ・・・ |

## modle\_idsを複数指定した場合
model\_idごとに集計されます。
(上記すべてのメソッドで共通）

**使用例**

Store(親テーブル)に以下のデータが入っています。
| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store\_1| ・・・ |
| 2 | 2 | store 2| ・・・ |

Sale(子テーブル）に以下のデータが入っています。
| id | store\_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 2 | 2023-05-01 | 200 | ・・・ |
| 102 | 1 | 2023-06-01 | 300 | ・・・ |
| 124 | 2 | 2023-06-01 | 400 | ・・・ |
| 125 | 1 | 2024-05-01 | 500 | ・・・ |
| 126 | 2 | 2024-05-01 | 600 | ・・・ |
| 125 | 1 | 2024-06-01 | 700 | ・・・ |
| 126 | 2 | 2024-06-01 | 800 | ・・・ |


**実行:** 

データが入っているmodelのクラスメソッド`godsum_weeks`を実行します。

```ruby
@stores = Store.all
@sales = Sale.godsum_weeks("2024-01-01", "2024-12-31", @stores.ids)
```

store\_id、年をグループ化した売上の合計が表示されます。
| store\_id |sale\_week | saleamt | r\_saleamt | z\_saleamt | r\_z\_saleamt| number | name |・・・ |
|---|---|---|---|---|---|---|---|---|
| 1 | 18 | 500 | 500 | 100 | 100 | 1 | store\_1 |
| 1 | 19 | 700 | 1200 | 300 | 400 | 1 | store\_1 |
| 2 | 18 | 500 | 500 | 200 | 200 | 2 | store\_2 |
| 2 | 19 | 700 | 1200 | 400 | 600 | 2 | store\_2 |

## 合計行

以下のような表で合計行を追加したい場合、
r\_列を使用することができます。

```ruby
@store = Store.find(params[:id])
@sales = Sale.godsum_days("2024-05-01","2024-05-31", @store.id)
```

```ruby
# html.erb
<% last_sale = nil %>
<% @sales.each do |sale| %>
  <tr>
    <td><%= sale.sale_month %>月</td>
    <td><%= sale.sale_day %>日</td>
    <td><%= sale.saleamt %></td>
  </tr>
  <% last_sale = sale.clone %>
<% end %>
<% if last_sale.present? %>
  <tr>
    <td>合計:</td>
    <td></td>
    <%= last_sale.r_saleamt %></td>
  </td>
<% end %>
```

## 設定
godsum\_modules.rbにある定数の値をDBの列名に合わせて変更することができます。
| 定数名 | 説明 | デフォルト |
|---|---|---|
| PARENT\_COLUMNS | 親テーブルの表示したい列名を配列で登録します。| number|
| SALEDATE | 子テーブルの日付列名 | saledate |
| SALE\_YEAR| 子テーブルの年列名 | sale\_year |
| SALE\_MONTH| 子テーブルの月列名 | sale\_month |
| SALE\_DAY| 子テーブルの日列名 | sale\_day |
| SALE\_CWEEK| 子テーブルの週列名 | sale\_cweek |
| SALE\_WDAY| 子テーブルの曜日列名 | sale\_wday |
| SUM\_COLUMNS| 子テーブルの集計したい列名を配列で登録します。 | saleamt |

## Godsum Modulesの仕組み
引数を元に売上、前年売上、累計を表示するSQLを順番に組み立てて最後に
ActiveRecodeにSQLを渡してデータを表示しています。

## godsumメソッド
上記で説明した3つのメソッド(godsum\_months,\_days,\_weeks)は
godsumメソッドのラッパーです。
godsumメソッドはprivateメソッドを使用してSQL文を作成し
最後に以下のコマンドを実行してActiveRecordを返します。

```ruby
 select(select_sql)
   .from(from_sql)
   .joins(inner_join_sql)
   .group(last_group_sql)
   .order(last_order_sql)
```
**godsum\_years**はロジックが違うため別のメソッドを使用しています。

## privateメソッド(\_months,\_days,\_weeks用)
SQLを生成するためのメソッドになっています。
%W[]を使用して配列のなかにSQLを記述します。
最後にjoinを使ってSQL文字列にしています。
メソッドが呼び出されるとインデントしたメソッドが実行されます。

- select\_sql
  - set\_select\_columns
- from\_sql
  - create\_inner\_table
    - set\_base\_select\_columns
      - set\_base\_hiduke
    - set\_base\_where\_columns
    - set\_base\_group\_columns
      - set\_base\_hiduke
- inner\_join\_sql
  - create\_iner\_table
    - set\_base\_inner\_join\_columns
    - set\_last\_iner\_join\_columns
- last\_group\_sql
  - set\_last\_group\_columns
- last\_order\_sql

メソッドの命名規則は以下の通りです。
| 接頭辞 | 意味 |
| --- | --- |
| \_sql | 最終SQL生成メソッド|
| create\_ | t1,t2を生成するメソッド|
| set\_ | select句、from句などを生成するメソッド|

## SQL
1つのテーブルに2つの別名(t1,t2)を付けて自己結合し今年、前年、累計を求めています。最後に親テーブル(t3)とinner joinしています。

| テーブル名 | 別名 | 説明|
|---|---|---|
| sale | t1 | caseを使用し今年と前年を表示 |
| sale | t2 | 累計用。t1と同じ構成 |
| store | t3 | マスタテーブル |

:daysを選択した場合実行されるSQLは以下の通りです。

```sql
select
   t3.number
  ,t3.name
  ,t1.store_id
  ,t1.sale_month
  ,t1.sale_day
  ,t1.saleamt
  ,t1.z_saleamt
  ,sum(t2.saleamt) as r_saleamt
  ,sum(t2.z_saleamt) as r_z_saleamt
from (
  select
     sales.store_id
    ,sales.sale_month
    ,sales.sale_day
    ,sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
  from sales
  where
    sales.saledate between '前年開始日' and '前年終了日' and sales.store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and sales.store_id in (Storeのid) 
  group by
     sales.store_id
    ,sales.sale_month
    ,sales.sale_day
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
) as t1
left outer join (
  select
     sales.store_id
    ,sales.sale_month
    ,sales.sale_day
    ,sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
  from sales
  where
    sales.saledate between '前年開始日' and '前年終了日' and sales.store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and sales.store_id in (Storeのid) 
  group by
     sales.store_id
    ,sales.sale_month
    ,sales.sale_day
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
) as t2 on
      t1.store_id = t2.store_id
  and t1.hiduke >= t2.hiduke 
left outer join store as t3 on
  t1.store_id = t3.store_id
group by
   t3.number
  ,t3.name
  ,t1.store_id
  ,t1.sale_month
  ,t1.sale_day
  ,t1.saleamt
  ,t1.z_saleamt
order by
   t1.sale_month
  ,t1.sale_day
  ,t3.number
```

## t1テーブルの説明
1つのテーブルで今年と前年の売上を表現するためにcaseを使用して値を振り分けています。
集計キーとなる列でgroupをかけて最終的な値を算出します。

```sql
  select
     sales.store_id
  1),sales.sale_month
    ,sales.sale_day
  2),sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
  3),case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
  from sales
  where
    sales.saledate between '前年開始日' and '前年終了日' and sales.store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and sales.store_id in (Storeのid) 
  group by
     sales.store_id
  1),sales.sale_month
    ,sales.sale_day
  4),case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
```

1)group\_typeによってここの列は変化します。

```sql
    ,sales.sale_month
    ,sales.sale_day
```

| group\_type | 列 |
| --- | --- |
| :months | sale\_month |
| :weeks | sale\_week |
| :days | sale\_month sale\_day|
| :wdays | sale\_cweek sale\_wday |

2)日付で振り分け

```sql
    ,sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
```

where句で絞り込まれた行のsaledateの値を見て前年と今年に振り分けています。
同時に前年なら接頭辞「z\_」を列名に付与、今年ならそのままの列名に指定しています。
対象外の日付が来た場合、0が代入されるのでsumを使って0の行を消すイメージになります。

3)left outer join用の列

```sql
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
```

t2テーブルとleft outer joinして累計値を求める際、今年の日付が必要になります。
そのため前年日付に1年追加した列を新たに追加しています。
日付を整数に変換してDBの差異をなくしました。
この列を追加したことで年をまたいだデータも
表示可能となっています。
またgroup\_typeによってcase内の計算式が以下のように変化します。
| group\_type | 計算式 |
| --- | --- |
| :months | (sales.sale\_year + 1) * 1000 + sales.month * 100|
| :weeks | (sales.sale\_year + 1) * 100 + sales.week|
| :days | (sales.sale\_year + 1) * 1000 + sales.month * 100 + sales.sale\_day|
| :wdays | (sales.sale\_year + 1) * 1000 + sales.cweek * 100 + sales.sale\_wday|

4)group句について

```sql
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
```

集計する際に3で追加した列も必要になるため追加していています。3との違いは最後の「as hiduke」
がありません。

## t2テーブルの説明
t2テーブルは累計を求めるためのテーブルで内容はt1と同じになっています。
このテーブルで重要な点は以下のleft outer joinです。

```sql
t2 on
      t1.store_id = t2.store_id
  and t1.hiduke >= t2.hiduke
```

3)で作成したhiduke列に不等号（t1.hiduke >= t2.hiduke)を使用することで
t1.saledateよりも小さいt2のデータをjoinしています。
これを最後にsumすれば日ごとの累計値を求めることができます。

## t3テーブルの説明

```sql
inner join store as t3 on
  t1.store_id = t3.store_id
```

親テーブルとinner joinすることで抽出したデータの属性値を表示可能にしています。

## 外側のselect句
t1,t2,t3がすべてjoinされたので最後のSELECTを行います。

```sql
select
   t3.number
  ,t3.name
  ,t1.store_id
1),t1.sale_month
1),t1.sale_day
  ,t1.saleamt
  ,t1.z_saleamt 
  ,sum(t2.saleamt) as r_saleamt
  ,sum(t2.z_saleamt) as r_z_saleamt
```

t1には今年と前年の売上が入っているのでそのまま表示、t2には累計用のデータが積み重なっているので
それを集計、ついでに接頭辞「r\_」を付与しています。

1)group\_typeによってここの列は変化します。

```sql
    ,t1.sale\_month
    ,t1.sale\_day
```
   
## 外側のgroup句
t2の累計値を求めるためt1,t3の列をグループにしています。

```sql
group by
   t3.number
  ,t3.name
  ,t1.store_id
1),t1.sale_month
1),t1.sale_day
  ,t1.saleamt
  ,t1.z_saleamt
```

1)group\_typeによってここの列は変化します。

```sql
    ,t1.sale_month
    ,t1.sale_day
```

## privateメソッド(godsum\_years用)
年ごとに集計し前年と比較、累計を求めるロジックはこれまでの
月ごと、週ごと、日ごととは異なるため別にしています。

- select\_year\_sql
  - set\_last\_select\_columns\_year
- from\_year\_sql
  - create\_outside\_table\_year
    - set\_outside\_select\_columns\_year
    - create\_base\_table\_year
      - set\_base\_select\_columns\_year
        - set\_base\_where\_columns\_year
        - set\_base\_group\_columns\_year
    - set\_base\_left\_outer\_join\_columns\_year
- left\_outer\_year\_sql
  - create\_outside\_table\_year
  - set\_last\_outer\_join\_columns\_year
    - set\_outside\_select\_columns\_year
    - create\_base\_table\_year
      - set\_base\_select\_columns\_year
        - set\_base\_where\_columns\_year
        - set\_base\_group\_columns\_year
- group\_year\_sql
  - set\_last\_group\_columns\_year
- order\_year\_sql
  - set\_last\_order\_columns\_year

## SQL
仮想テーブルも含め5つのテーブルをつなぎ合わせています。

| テーブル名 | 別名 | 説明|
|---|---|---|
| sale | t1 | 今年用の売上 |
| sale | t2 | 前年用の売上 |
| t1,t2 | t5 | 今年と前年を併せたテーブル |
| t1,t2 | t6 | 同上(累計用)|
| store | t7 | マスタテーブル |

SQLは以下の通りです。

```sql
select
  /* last_select */
   t5.sale_year
  ,t5.sale_id
  ,t7.number
  ,t7.name
  ,t5.saleamt
  ,t5.z_saleamt
  ,sum(t6.saleamt) as r_saleamt
  ,sum(t6.z_saleamt) as r_z_saleamt
from (
  /* t5 start */
  select
     t1.sale_year
    ,t1.sale_id
    ,t1.saleamt
    ,t2.saleamt as z_saleamt
  from (
    /* t1 start */
    select 
       sale_sales.sale_year
      ,sale_sales.sale_id
      ,sum(sale_sales.saleamt) as saleamt
      ,sale_sales.sale_year as hiduke
    from sale_sales 
    where 
          sale_sales.saledate between '開始日' and '終了日' 
      and sale_sales.sale_id in (Storeのid)
    group by 
      sale_sales.sale_year
     ,sale_sales.sale_id
    ) as t1
    /* t1 end */
    left outer join (
    /* t2 start */
    select 
       sale_sales.sale_year
      ,sale_sales.sale_id
      ,sum(sale_sales.saleamt) as saleamt
      ,sale_sales.sale_year + 1 as hiduke
    from sale_sales 
    where 
          sale_sales.saledate between '開始日' and '終了日' 
      and sale_sales.sale_id in (Storeのid)
    group by 
       sale_sales.sale_year
      ,sale_sales.sale_id
    ) as t2 on
    /* t2 end */
  /* t1 t2 inner join start */
      t1.sale_year = t2.hiduke
  and t1.sale_id = t2.sale_id
  /* t1 t2 inner join end */
  /* t5 end */
) as t5
 left outer join (
   /* t6 start */
   select
      t1.sale_year
     ,t1.sale_id
     ,t1.saleamt
     ,t2.saleamt as z_saleamt
   from (
     /* t1 start */
     select 
        sale_sales.sale_year
       ,sale_sales.sale_id
       ,sum(sale_sales.saleamt) as saleamt
       ,sale_sales.sale_year as hiduke
     from sale_sales 
     where 
           sale_sales.saledate between '開始日' and '終了日' 
       and sale_sales.sale_id in (Storeのid)
     group by 
        sale_sales.sale_year
       ,sale_sales.sale_id
     ) as t1
     /* t1 end */
     left outer join (
     /* t2 start */
     select 
        sale_sales.sale_year
       ,sale_sales.sale_id
       ,sum(sale_sales.saleamt) as saleamt
       ,sale_sales.sale_year + 1 as hiduke
     from sale_sales 
     where 
          sale_sales.saledate between '開始日' and '終了日' 
      and sale_sales.sale_id in (Storeのid)
     group by 
        sale_sales.sale_year
       ,sale_sales.sale_id
     /* t2 end */
   ) as t2 on
   /* t1 t2 inner join start */
       t1.sale_year = t2.hiduke
   and t1.sale_id = t2.sale_id
   /* t1 t2 inner join end */
   /* t6 end */
) as t6 on
  /* t5 t6 left outer join start */
      t5.sale_year >= t6.sale_year
  and t5.sale_id = t6.sale_id
  /* t5 t6 inner join end */
/* t7 inner join start */
inner join stores as t7 on
  t5.sale_id = t7.id
/* t7 inner join end */
group by
  /* last_group */
   t5.sale_year
  ,t5.sale_id
  ,t5.saleamt
  ,t5.z_saleamt
  ,t7.number
  ,t7.name
order by
  /* last_order */
   t7.number
  ,t5.sale_year;
```

## 1) t1テーブル
model\_id、年ごとに集計をします。

## 2) t2テーブル
model\_id、年ごとに集計をします。
同時にhiduke(sale\_year + 1)列を追加しています。

## 3) t5テーブル
t1とt2をleft outer joinします。
joinする際、t1.sale\_year = t2.hiduke(sale\_year + 1)と
することでt1は今年の売上、t2は前年売上になります。

## 4) t6テーブル
累計用にt5と同じテーブルを用意しt5とleft outer joinします。
その際、t5.sale\_year >= t6.sale\_year とすることで
今年よりも小さい行を積み重ねています。

## 5) t7テーブル
マスタテーブルを用意しt5とinner joinします。

## 6) 仕上げ
t5から今年と前年の売上、t6から累計用のデータを選択しsumします。
t5の列をgroup byして完成です。
