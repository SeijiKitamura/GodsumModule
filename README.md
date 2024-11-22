# GodsumModule
ActiveRecord用moduleです。
期間中の売上はもちろん前年売上も簡単に表示出ます。
また集計方法も年別、月別、週別、日別に対応しています。
集計列も自由に選べ「累計」も表示可能です。

## DBテーブルと列について
マスタ情報を管理している親テーブルと売上情報を管理している子テーブルが必要です。

**Store（親テーブル)**
親テーブルには名前や店舗番号などの属性が保存されています。
| | 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|★| number | integer | 店番号 | 
|★| name | string | 店名 | 
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

**Modelについて**
上記テーブルのModelは以下の通りとなります。

**Store(親モデル）**
```
# 親model
class Store < Activerecord
  has_many :sales
end
```

**Sale(子モデル）**
```
# 子model
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

```
class Sale < Activerecord
  include GodsumModules
  belongs_to :store
  ・・・・
　・・・・
end
```

## 使い方
子モデルにクラスメソッド(godsum_years,godsum_months,godsum_weeks,godsum_days)が追加されます。
これらを使用してデータを集計します。

## 戻り値
.where などで呼び出したときと同じようなデータが返ってきます。
指定した集計列に加えてz_、r_、r_z_が先頭に付加された列名が追加されます。
それぞれの意味は以下の通りです。

| 接頭辞 | 意味 | 例 ||
|---|---|---|---|
| 無印 | 今年 | saleamt | 今年売上 |
| z_ | 前年 | z_saleamt | 前年売上 |
| r_ | 今年累計| r_saleamt | 今年累計売上 |
| r_z_ | 前年累計| r_z_saleamt | 前年累計売上 |

## godsumメソッド
4つのメソッドのそれぞれの使い方を説明します。

**godsum_years(startady, lastday, model_ids)**
年別の合計を表示するメソッドです。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model_ids | 集計するIDを指定します。（複数可)|

**使用例**
Store(親テーブル)に以下のデータが入っています。
| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store_1| ・・・ |

Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・ | 
|---|---|---|---|---|
| 124 | 1 | 2022-01-01 | 100 | ・・・ |
| 125 | 1 | 2023-01-01 | 200 | ・・・ |
| 126 | 1 | 2024-01-01 | 300 | ・・・ |

**実行:** データが入っているmodelのクラスメソッド`godsum_year`を実行します。
```
@store = Store.find(params[:id])
@sales = Sale.godsum_years("2024-01-31", "2024-12-31", @store.id)
```

**結果:** 年を集計キーに今年、前年、累計が集計されます。
| store_id |sale_year | saleamt | r_saleamt | z_saleamt | r_z_saleamt| number | name |・・・ |
| --- | --- | --- | --- | --- | --- |--- | --- |--- |
| 1 | 2023 | 200 | 200 | 100 | 100 | 1 | store 1 | ・・・|
| 1 | 2024 | 300 | 500 | 200 | 300 | 1 | store 1 |  ・・・|

**godsum_months(startady, lastday, model_ids)**
月別の合計を表示するメソッドです。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model_ids | 集計するIDを指定します。（複数可)|

**使用例**
Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 1 | 2023-06-01 | 200 | ・・・ |
| 102 | 1 | 2023-07-01 | 300 | ・・・ |
| 124 | 1 | 2024-05-01 | 400 | ・・・ |
| 125 | 1 | 2024-06-01 | 500 | ・・・ |
| 126 | 1 | 2024-07-01 | 600 | ・・・ |

**実行:** データが入っているmodelのクラスメソッド`godsum_months`を実行します。
```
@store = Store.find(params[:id])
@sales = Sale.godsum_months("2024-05-01","2024-7-31", @store.id)
```

**結果** 月を集計キーに今年、前年、累計が集計されます。
| store_id | sale_month | saleamt | r_sale_amt| z_saleamt  | r_z_saleamt | ・・・ |
| --- | --- | --- | --- | --- | --- |--- |
| 1 | 5 | 400 | 400 | 100 | 100 | ・・・ |
| 1 | 6 | 500 | 900 | 200 | 300 | ・・・ |
| 1 | 7 | 600 | 1500 |300 | 600 | ・・・ |

**godsum_days(startady, lastday, model_ids)**
日別の合計を表示するメソッドです。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model_ids | 集計するIDを指定します。（複数可)|

**使用例**
Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 1 | 2023-05-02 | 200 | ・・・ |
| 102 | 1 | 2023-05-03 | 300 | ・・・ |
| 124 | 1 | 2024-05-01 | 400 | ・・・ |
| 125 | 1 | 2024-05-02 | 500 | ・・・ |
| 126 | 1 | 2024-05-03 | 600 | ・・・ |

**実行:** データが入っているmodelのクラスメソッド`godsum_months`を実行します。
```
@store = Store.first
@sales = Sale.godsum_days("2024-05-01", "2024-05-03", @store.id)
```

**結果** 月、日を集計キーに今年、前年、累計が集計されます。
| sale_month | sale_day | saleamt | z_saleamt | r_saleamt | r_z_saleamt |
|---|---|---|---|---|---|
| 5 | 1 | 400 | 400 | 100 | 100 |
| 5 | 2 | 500 | 900 | 200 | 300 |
| 5 | 3 | 600 | 1500 | 300 | 600 |

**godsum_weeks(startady, lastday, model_ids)**
週別の合計を表示するメソッドです。

**引数**
| 引数 | 説明 |
| --- | --- |
| startday | 集計する開始日を入力します。 |
| lastday  | 集計する終了日を入力します。 |
| model_ids | 集計するIDを指定します。（複数可)|


**使用例**
Sale（子テーブル）に同上のデータが入っています。

**実行:** データが入っているmodelのクラスメソッド`godsum_weeks`を実行します。
```
@store = Store.find(params[:id])
@sales = Sale.godsum_weeks("2024-05-01", "2024-05-08", @store.id)
```

**結果:** 週数を集計キーに今年、前年、累計が集計されます。
| sale_cweek | saleamt | z_saleamt | r_saleamt | r_z_saleamt |
|---|---|---|---|---|
| 18 | ・・・ | ・・・ | ・・・ | ・・・ |


**第3引数:modle_idsを複数指定した場合**
model_idごとに集計されます。

**使用例**
Store(親テーブル)に以下のデータが入っています。
| id | number | name | ・・・|
|---|---|---|---|
| 1 | 1 | store_1| ・・・ |
| 2 | 2 | store 2| ・・・ |

Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・|
|---|---|---|---|---|
| 100 | 1 | 2023-05-01 | 100 | ・・・ |
| 101 | 2 | 2023-05-01 | 200 | ・・・ |
| 102 | 1 | 2023-06-01 | 300 | ・・・ |
| 124 | 2 | 2023-06-01 | 400 | ・・・ |
| 125 | 1 | 2024-05-01 | 500 | ・・・ |
| 126 | 2 | 2024-05-01 | 600 | ・・・ |
| 125 | 1 | 2024-06-01 | 700 | ・・・ |
| 126 | 2 | 2024-06-01 | 800 | ・・・ |


**実行:** データが入っているmodelのクラスメソッド`godsum_months`を実行します。
```
@store_ids = Store.all.ids
@sales = Sale.godsum_months("2024-01-01", "2024-12-31", @store_ids)
```

年を集計キーにすべてのお店の売上が集計されます。
| store_id |sale_month | saleamt | r_saleamt | z_saleamt | r_z_saleamt| number | name |・・・ |
|---|---|---|---|---|---|---|---|---|
| 1 | 5 | 500 | 500 | 100 | 100 | 1 | store_1 |
| 1 | 6 | 700 | 1200 | 300 | 400 | 1 | store_1 |
| 2 | 5 | 500 | 500 | 200 | 200 | 2 | store_2 |
| 2 | 6 | 700 | 1200 | 400 | 600 | 2 | store_2 |

### 合計行
以下のような表で合計行を追加したい場合、通常はもう一度DBを使用して集計するかeachの中で累計値を加算するしかありません。
しかしこのメソッドを使用すると最終データのr_列に合計が入っています。

```
@store = Store.find(params[:id])
@sales = Sale.godsum_days("2024-05-01","2024-05-31", @store.id)
```

| sale_month | sale_day | saleamt |
|---|---|---|
| 5 | 1 | 400 |
| 5 | 2 | 500 | 
| 5 | 3 | 600 |
| 合計| | <%= @sales.last.r_saleamt %>|

結局SQLが2回走りますが合計を算出するための新たなコードを
記述する必要はありません。

## 設定
godsum_modules.rbにある以下の定数をDBの列名に合わせて変更することができます。
| 定数名 | 説明 | デフォルト |
|---|---|---|
| PARENT_COLUMNS | 親テーブルの表示したい列名を配列で登録します。| name,number|
| SALEDATE | 子テーブルの日付列名 | saledate|
| SALE_YEAR| 子テーブルの年列名 | sale_year|
| SALE_MONTH| 子テーブルの月列名 | sale_month|
| SALE_DAY| 子テーブルの日列名 | sale_day|
| SALE_CWEEK| 子テーブルの週列名 | sale_cweek|
| SALE_WDAY| 子テーブルの曜日列名 | sale_wday|
| SUM_COLUMNS| 子テーブルの集計したい列名を配列で登録します。 | saleamt |

## Godsum Modulesの仕組み
引数を元に売上、前年売上、累計を表示するSQLを順番に組み立てて最後に
ActiveRecodeにSQLを渡してデータを表示しています。

### godsumメソッド
上記で説明した4つのメソッド(godsum_years,_months,_days,_weeks)は
godsumメソッドのラッパーです。
godsumメソッドはprivateメソッドを使用してSQL文を作成し
最後に以下のコマンドを実行してActiveRecordを返します。
```
 select(select_sql)
   .from(from_sql)
   .joins(inner_join_sql)
   .group(last_group_sql)
   .order(last_order_sql)
```

### privateメソッド
SQLを生成するためのメソッドになっています。
%W[]を使用した配列のなかにSQLを記述しjoinを使用して文字列にしています。
メソッドの命名規則は以下の通りです。

| 接頭辞 | 意味 |
| --- | --- |
| _sql | 最終SQL生成メソッド|
| create_ | t1,t2を生成するメソッド|
| set_ | select句、from句などを生成するメソッド|

### SQL
1つのテーブルに2つの別名を付けて自己結合し今年、前年、累計を求めています。
| テーブル名 | 別名 | 説明|
|---|---|---|
| sale | t1 | caseを使用し今年と前年を表示 |
| sale | t2 | 累計用。t1と同じ構成 |
| store | t3 | マスタテーブル |

日別売上を選択した場合実行されるSQLは以下の通りです。
```
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
inner join (
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
inner join store as t3 on
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

### t1テーブルの説明
1つのテーブルで今年と前年の売上を表現するためにcaseを使用して値を振り分けています。
集計キーとなる列でgroupをかけて最終的な値を算出します。
```
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

1)group_typeによってここの列は変化します。
```
    ,sales.sale_month
    ,sales.sale_day
```

| group_type | 列 |
| --- | --- |
| :years | sale_year |
| :months | sale_month |
| :weeks | sale_week |
| :days | sale_month sale_day|
| :wdays | sale_cweek sale_wday |

2)日付で振り分け
```
    ,sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
```
where句で絞り込まれた行のsaledateの値を見て前年と今年に振り分けています。
同時に前年なら接頭辞「z_」を列名に付与、今年ならそのままの列名に指定しています。
対象外の日付が来た場合、0が代入されるのでsumを使って0の行を消すイメージになります。

3)inner join用の列
```
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
```
t2テーブルとinner joinして累計値を求める際、今年の日付が必要になります。
そのため前年日付に1年追加した列を新たに追加しています。
日付を整数に変換してDBの差異をなくしました。
この列を追加したことで年をまたいだデータも
表示可能となっています。
またgroup_typeによってcase内の計算式が以下のように変化します。
| group_type | 計算式 |
| --- | --- |
| :years | (sales.sale_year + 1) |
| :months | (sales.sale_year + 1) * 1000 + sales.month * 100|
| :weeks | (sales.sale_year + 1) * 100 + sales.week|
| :days | (sales.sale_year + 1) * 1000 + sales.month * 100 + sales.sale_day|
| :wdays | (sales.sale_year + 1) * 1000 + sales.cweek * 100 + sales.sale_wday|

4)group句について
```
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
```
集計する際に3で追加した列も必要になるため追加していています。3との違いは最後の「as hiduke」
がありません。

### t2テーブルの説明
t2テーブルは累計を求めるためのテーブルで内容はt1と同じになっています。
このテーブルで重要な点は以下のinner joinです。
```
t2 on
      t1.store_id = t2.store_id
  and t1.hiduke >= t2.hiduke
```
3)で作成したhiduke列に不等号（t1.hiduke >= t2.hiduke)を使用することで
t1.saledateよりも小さいt2のデータをjoinしています。
これを最後にsumすれば日ごとの累計値を求めることができます。

### t3テーブルの説明
```
inner join store as t3 on
  t1.store_id = t3.store_id
```
親テーブルとinner joinすることで抽出したデータの属性値を表示可能にしています。

### 外側のselect句
t1,t2,t3がすべてinner joinされたので最後のSELECTを行います。
```
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
それを集計、ついでに接頭辞「r_」を付与しています。

1)group_typeによってここの列は変化します。
```
    ,t1.sale_month
    ,t1.sale_day
```
   
### 外側のgroup句
t2の累計値を求めるためt1,t3の列をグループにしています。

```
group by
   t3.number
  ,t3.name
  ,t1.store_id
1),t1.sale_month
1),t1.sale_day
  ,t1.saleamt
  ,t1.z_saleamt
```
1)group_typeによってここの列は変化します。
```
    ,t1.sale_month
    ,t1.sale_day
```
