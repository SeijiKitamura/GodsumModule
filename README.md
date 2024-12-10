# GodsumModule
Ruby on Rails / ActiveRecord

| 月 | 日 | 売上 | 累計売上 | 前年売上 | 前年累計 |
|---|---|---|---|---|---|
| 4 | 1 | 100 | ★**100** | ★**50** | ★**50** |
| 4 | 2 | 120 | ★**220** | ★**80** | ★**130** |
| 4 | 3 | 130 | ★**350** | ★**90** | ★**220** |

★ 部分を簡単に集計できるActiveRecord用Moduleです。

## はじめに
データの集計と言えばsum関数ですが集計したデータを前年
と比較したり累計や合計を求めて1つの表にしようとすると
思いのほか苦労します。
GodsumModuleを使用することで今年のデータはもちろん、
前年や累計も簡単に集計できます。
グループ化する列も「年、月、週、日」の4つから
選択することができてさまざまデータ分析に使用できます。
Railsを使用して会社の売上データを管理したい方におすすめ
のModuleです。

## 前提条件(DBテーブルと列)
マスタ情報を管理している親テーブルと売上情報を管理している
子テーブルが必要です。

**Store（親テーブル)**

親テーブルには名前や店舗番号などの属性が保存されています。

| | 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|| number | integer | 店番号 | 
|| name | string | 店名 | 
|| ・・・ | ・・・ | ・・・ |
|| ・・・ | ・・・ | ・・・ |

★-> 必須列

**Sale（子テーブル)**

子テーブルには売上データが格納されています。
日付列のほかに年、月、日などの日付属性列が必要です。

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
  include GodsumModules
  has_many :sales
end
```

**Sale(子モデル）**
```ruby
class Sale< Activerecord
  belongs_to :store
  validates :saledate, presence: true
　before_save :set_date 
  ・・・・
　・・・・
  private

  # saledate列に入った値を使用して各列を代入する
  def set_date
    sale_year = saledate.year
    sale_month = saledate.month
    sale_day = saledate.day
    sale_cweek = saledate.cweek
    sale_wday = saledate.wday
  end
end
```

## インストール
app/model/concernsにgodsum_modules.rbを配置してください。
その後、マスタを管理しているmodelに以下のコードを記述します。

```ruby
class Store < Activerecord
  include GodsumModules
  has_many :sales
  ・・・・
　・・・・
end
```

## 設定
godsum\_modules.rbにある定数の値をDBの列名に合わせて変更することができます。
| 定数名 | 説明 | デフォルト |
|---|---|---|
| SALEDATE | 子テーブルの日付列名 | saledate |
| SALE\_YEAR| 子テーブルの年列名 | sale\_year |
| SALE\_MONTH| 子テーブルの月列名 | sale\_month |
| SALE\_DAY| 子テーブルの日列名 | sale\_day |
| SALE\_CWEEK| 子テーブルの週列名 | sale\_cweek |
| SALE\_WDAY| 子テーブルの曜日列名 | sale\_wday |
| SUM\_COLUMNS| 子テーブルの集計したい列名を配列で登録します。 | [saleamt] |

## 使い方
親モデルにクラスメソッドが追加されます。
これらを使用してデータを集計します。

## 戻り値
.where などで呼び出したときと同じようなデータが返ってきます。
指定した集計列に加えてz\_、r\_、r\_z\_が先頭に付加された
列名が追加されます。それぞれの意味は以下の通りです。

| 接頭辞 | 意味 | 例 ||
|---|---|---|---|
| 無印 | 今年 | saleamt | 今年売上 |
| z\_ | 前年 | z\_saleamt | 前年売上 |
| r\_ | 今年累計| r\_saleamt | 今年累計売上 |
| r\_z\_ | 前年累計| r\_z\_saleamt | 前年累計売上 |

## 使用できるメソッド
6つのメソッドが追加されます。以下にそれぞれの使い方を説明します。

## godsum\_years
年別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定し、model\_idsに親テーブルの
idを指定するとmodel\_id、年でグループ化された値の合計を取り出す
ことができます。

```ruby
Model.godsum_years(startday, lastday, *model_ids, **options)
```

**引数**

| 引数 | 省略 | 説明 |
|---|---|---|
| startday | 不可 | 集計開始日を入力します。 |
| lastday  | 不可 | 集計終了日を入力します。 |
| options[:model] | 可 | 集計するModelを指定します |
| options[:sum_columns] | 可 | 集計する列を指定します |

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
@store = Store.first
@sales = Store.godsum_years("2022-01-01", "2024-12-31")
              .where(stores: { id: @store.id })
```

**結果:** 

store\_id、年でグループ化したsaleamtが集計されます。

| store\_id |sale\_year | saleamt | r\_saleamt | z\_saleamt | r\_z\_saleamt| number | name |・・・ |
| --- | --- | --- | --- | --- | --- |--- | --- |--- |
| 1 | 2022 | 100 | 100 | | | 1 | store 1 | ・・・|
| 1 | 2023 | 200 | 300 | 100 | 100 | 1 | store 1 | ・・・|
| 1 | 2024 | 300 | 600 | 200 | 300 | 1 | store 1 |  ・・・|


## godsum\_months
月別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定すると
月でグループ化された値の合計を取り出すことができます。

```ruby
Model.godsum_months(startday, lastday, **options)
```

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model\_ids | 集計するIDを指定します。（複数可)|
| options[:model] | 可 | 集計するModelを指定します |
| options[:sum_columns] | 可 | 集計する列を指定します |

**戻り値**

ActiveRecord\_Relationが返ります。

列名は以下の通りです。

| 列名 | 説明 |
| --- | --- |
| sale_month | 月 |
| (model)\_id | 親モデルのid |
| saleamt | 期間売上 |
| z\_saleamt | 期間前年売上 |
| r\_saleamt | 期間累計売上 |
| r\_z\_saleamt | 期間累計前年売上 |

**注意事項**

- startdayとlastdayの間隔は1年未満にしてください。
  - 1年以上を指定してもエラーにはなりませんが
    ロジック上、正しい値は表示されません。

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
@sales = Store.godsum_months("2024-05-01","2024-7-31")
              .where(stores: { id: @store.id })
```

**結果:** 

store\_id、月でグループ化したsaleamtが集計されます。

| store\_id | sale\_month | saleamt | r\_sale\_amt| z\_saleamt  | r\_z\_saleamt | ・・・ |
| --- | --- | --- | --- | --- | --- |--- |
| 1 | 5 | 400 | 400 | 100 | 100 | ・・・ |
| 1 | 6 | 500 | 900 | 200 | 300 | ・・・ |
| 1 | 7 | 600 | 1500 |300 | 600 | ・・・ |

## godsum\_days
日別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定しmodel\_id、月、日で
グループ化された値の合計を取り出すことができます。

```ruby
Model.godsum_days(startday, lastday, *model_ids, **options)
```

| 引数 | 省略 | 説明 |
|---|---|---|
| startday | 不可 | 集計する開始日を入力します。 |
| lastday  | 不可 | 集計する終了日を入力します。 |
| options[:model] | 可 | 集計するModelを指定します |
| options[:sum_columns] | 可 | 集計する列を指定します |


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
  - 1年以上を指定してもエラーにはなりませんが
    ロジック上、正しい値は表示されません。

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
@sales = Store.godsum_days("2024-05-01", "2024-05-03")
              .where(stores: { id: @store.id })
```

**結果:** 

store\_id、月、日でグループ化したsaleamtが集計されます。

|store\_id| sale\_month | sale\_day | saleamt | r\_saleamt | z\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|---|---|
| 1 | 5 | 1 | 400 | 400  | 100 | 100 |
| 1 | 5 | 2 | 500 | 900  | 200 | 300 |
| 1 | 5 | 3 | 600 | 1500 | 300 | 600 |

## godsum\_weeks
週別の合計を表示するメソッドです。
startday,lastdayに任意の期間を指定すると
model_id、週でグループ化された値の合計を取り出すことができます。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| options[:model] | 可 | 集計するModelを指定します |
| options[:sum_columns] | 可 | 集計する列を指定します |

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
  - 1年以上を指定してもエラーにはなりませんが
    ロジック上、正しい値は表示されません。
- 年末に正しい値が表示されない可能性があります。
  - 7年に一度前年の週数が存在しない場合があります。

**例1 1店舗の売上合計を求める**

**実行:** 

```ruby
@store = Store.find(params[:id])
@sales = Stgre.godsum_weeks("2024-05-01", "2024-05-08")
              .where(stores: {id: @store.id })
```

**結果:** 

store\_id、週でグループ化したsaleamtが集計されます。

| store\_id | sale\_cweek | saleamt | z\_saleamt | r\_saleamt | r\_z\_saleamt |
|---|---|---|---|---|---|
| 1 | 18 | ・・・ | ・・・ | ・・・ | ・・・ |


## godsum_sub
親モデルIDでグループ化した値を表示します。

```ruby
@sales = Store.godsum_sub("2024-05-01","2024-05-31")
```

| id | saleamt | z\_saleamt |
|---|---|---|
| 1 |  ・・・ | ・・・ |
| 2 |  ・・・ | ・・・ |

## godsum_sub
期間合計値を表示します。

```ruby
@sales = Store.godsum_grand("2024-05-01","2024-05-31")
```

| saleamt | r\_saleamt |
|---|---|
|  ・・・ | ・・・ |
|  ・・・ | ・・・ |
