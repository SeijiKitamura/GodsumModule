# RuikeiModule
Railsのmodel用moduleです。指定したDB列の合計（累計額）を簡単に算出することができます。

## インストール
app/model/concernsにRuikeiModules.rbを配置してください。
その後、データを管理しているmodelに以下のコードを記述します。
```
class Sale < Activerecord
  include RuikeiModules
end
```
## 使い方
子モデルにクラスメソッドassembleが追加されています。
これを使用してデータを収集します。

```
Sale.assemble([model_ids], [kikan], group_type = (:years|:months|:weeks|:days), [order_columns])
```
### 引数
assembleを呼び出す際に必要な引数は以下の通りです。

|| 引数 | 引数名 | 型 | 省略 | 説明 |
|---|---|---|---|---|
|★| 第1引数 | model_ids | 配列 | 不可 | 売上集計したい親Modelのidを入れます。|
|★| 第2引数 | kikan | 配列 | 不可 | 前年開始日、前年終了日、今年開始日、今年終了日の順｜
|| 第3引数 | group_type | 配列 | 可 | 集計の基準となる列名を配列で指定します。(省略した場合は:days)|
|| 第4引数 | option_order_columns | 可 | 配列 | 並び変えとなる列名を配列で指定します|

### 戻り値
.where などで呼び出したときと同じようなデータが返ってきます。
指定した列名とは別にz_、r_、r_z_が先頭に付加された列名が追加されます。
それぞれの意味は以下の通りです。
| 接頭辞 | 意味 | 例 ||
|---|---|---|---|
| 無印 | 今年 | saleamt | 今年売上 |
| z_ | 前年 | z_saleamt | 前年売上 |
| r_ | 今年累計| r_saleamt | 今年累計売上 |
| r_z_ | 前年累計| r_z_saleamt | 前年累計売上 |

## 例1 1日の売上（前年同日付き）
前年同日と比較した1日の売上結果を表示したい場合、以下のようになります。

### Store(親テーブル)に以下のデータが入っています。
| id | number | name | ・・・| updated_at |
|---|---|---|---|---|
| 1 | 1 | example store 1| ・・・ | 2024-1-1 00:00:00 |
| 2 | 2 | example store 2| ・・・ | 2024-1-1 00:00:01 |

### Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・ | updated_at |
|---|---|---|---|---|---|
| 123 | 1 | 2023-05-01 | 100 | ・・・ | 2023-05-01 23:34:00 |
| ・・・ | ・・・ | ・・・ | ・・・ | ・・・ | ・・・ |
| 598 | 1 | 2024-05-01 | 300 | ・・・ | 2024-05-01 22:34:00 |

### データ収集します。
```
# Sales.controller
def show
  store = Store.find(params[:id])
  # kikanは「前年開始日、前年終了日、今年開始日、今年終了日」の順番で用意します。
  kikan = %w[ 2023-05-01 2023-05-01 2024-05-01 2024-05-01]
  @sales = Sale.assemble([store.id], kikan)
end
```
```
# views/sales/show.html.erb
@sales.each do |sale|
　日付: <%= sale.sale_month %>月<%= sale.sale_day %>日
  今年売上：<%= sale.saleamt %>   <- 300と表示されます。
  前年売上: <%= sale.z_saleamt %> <- 100と表示されます。
end
```
## 例2 今月の日別売上（前年同日、累計値付き）
### Sale(子テーブル）に以下のデータが入っています。
| id | store_id | saledate | saleamt | ・・・ | updated_at |
|---|---|---|---|---|---|
| 124 | 2 | 2023-05-01 | 100 | ・・・ | 2023-05-01 23:44:00 |
| 125 | 2 | 2023-05-02 | 200 | ・・・ | 2023-05-02 23:44:00 |
| 126 | 2 | 2023-05-03 | 300 | ・・・ | 2023-05-03 23:44:00 |
| ・・・ | ・・・ | ・・・ | ・・・ | ・・・ | ・・・ |
| 599 | 2 | 2024-05-01 | 400 | ・・・ | 2024-05-01 22:44:00 |
| 600 | 2 | 2024-05-02 | 500 | ・・・ | 2023-05-02 23:44:00 |
| 601 | 2 | 2024-05-03 | 600 | ・・・ | 2023-05-03 23:44:00 |

### データ収集します。
```
# Sales.controller
def show
  store = Store.find(params[:id])
  # kikanは「前年開始日、前年終了日、今年開始日、今年終了日」の順番で用意します。
  kikan = %w[ 2023-05-01 2023-05-03 2024-05-01 2024-05-03]
  @sales = Sale.assemble([store.id], kikan)
end
```
@salesを使用して以下のようなデータを表示することが可能です。
| sale_month | sale_day | saleamt | z_saleamt | r_saleamt | r_z_saleamt |
|---|---|---|---|---|---|
| 月 | 日 | 今年売上 | 今年累計 | 前年売上 | 前年累計 |
| 5 | 1 | 400 | 400 | 100 | 100 |
| 5 | 2 | 500 | 900 | 200 | 300 |
| 5 | 3 | 600 | 1500 | 300 | 600 |

## DBテーブルと列について
マスタ情報を管理している親テーブルと売上情報を管理している子テーブルが必要です。

### Store（親テーブル)
親テーブルには名前や店舗番号などの属性を保存します。
| | 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|| number | integer | 店番号 | 
|| name | string | 店名 | 
|| ・・・ | ・・・ | ・・・ |
|| ・・・ | ・・・ | ・・・ |
|★| created_at| datetime| |
|★| updated_at| datetime| |

★-> 必須列

### Sale（子テーブル)
子テーブルには売上データが格納されます。
|| 列名 | 型 | 説明
|---|---|---|---|
|★| id | integer | | 
|★| store_id | integer | 店ID |
|★| saledate| date | 日付 (必須）|
|★| saleamt | integer | 売上 | 
|| ・・・ | ・・・ | ・・・ |
|| ・・・ | ・・・ | ・・・ |
|★| sale_year | integer | 西暦 |
|★| sale_month | integer | 月 |
|★| sale_day | integer | 日 |
|★| sale_cweek | integer | 週数 |
|★| sale_wday | integer | 曜日  |
|★| created_at| datetime| |
|★| updated_at| datetime| |

★-> 必須列

## Modelについて
上記テーブルに関連したModelは以下の通りとなります。

### Store(親モデル）
```
# 親model
class Store < Activerecord
  has_many :sales
end
```

### Sale(子モデル）
```
# 子model
class Sale< Activerecord
  include RuikeiModules
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

## Ruikei Modulesの仕組み
引数を元に売上、前年売上、累計を表示するSQLを順番に組み立てて最後にActiveRecodeにSQLを渡してデータを表示しています。

### SQL
日別売上を選択した場合のSQLは以下の通りです。
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
    sales.saledate between '前年開始日' and '前年終了日' and store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and store_id in (Storeのid) 
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
    sales.saledate between '前年開始日' and '前年終了日' and store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and store_id in (Storeのid) 
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
### SQL構成
1つのテーブルに2つの別名を付けて自己結合し今年、前年、累計を求めています。
| テーブル名 | 別名 | 説明|
|---|---|---|
| sale | t1 | caseを使用し今年と前年を表示 |
| sale | t2 | 累計用。t1と同じ構成 |
| store | t3 | マスタテーブル |

### t1テーブルの説明
1つのテーブルで今年と前年の売上を表現するためにcaseを使用して値を振り分けている。
集計キーとなる列でgroupをかけて最終的な値を算出している
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
    sales.saledate between '前年開始日' and '前年終了日' and store_id in (Storeのid) 
    or
    sales.saledate between '今年開始日' and '今年終了日' and store_id in (Storeのid) 
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

1)group_typeによってここの列は変化する。
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

2)日付で振り分け
```
    ,sum(case when sales.saledate between '前年開始日' and '前年終了日' then sales.saleamt else 0 end) as z_saleamt
    ,sum(case when sales.saledate between '今年開始日' and '今年終了日' then sales.saleamt else 0 end) as saleamt
```
where句で絞り込まれた行のsaledateの値を見て前年と今年に振り分けている。
同時に前年なら接頭辞「z_」を列名に付与、今年ならそのままの列名に指定している。
対象外の日付が来た場合、0が代入されるのでsumを使って0の行を消すイメージになる。

3)inner join用の列
```
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end as hiduke
```
t2テーブルとinner joinして累計値を求める際、今年の日付が必要になってくる。
そのため前年比付けに1年追加した列を新たに追加している。
日付を整数に変換して扱いやすくした。この列を追加したことで年をまたいだデータも
表示可能となる。
またgroup_typeによってcase内の計算式が以下のように変化する。
| group_type | 計算式 |
| --- | --- |
| :years | (sales.sale_year + 1) |
| :months | (sales.sale_year + 1) * 1000 + sales.month * 100|
| :weeks | (sales.sale_year + 1) * 100 + sales.week|
| :dayss | (sales.sale_year + 1) * 1000 + sales.month * 100 + sales.sale_day|

4)group句について
```
    ,case when sales.saledate between between '前年開始日' and '前年終了日' then
       (sales.sale_year + 1) * 1000 + sales.sale_month * 100 + sales.sale_day
     else
       sales.sale_year * 1000 + sales.sale_month * 100 + sales.sale_day 
     end
```
集計する際に3で追加した列も必要になるため追加している。3との違いは最後の「as hiduke」
がない。

### t2テーブルの説明
t2テーブルは累計を求めるためのテーブルで内容はt1と同じになっている。
このテーブルで重要な点は以下のinner join。
```
t2 on
      t1.store_id = t2.store_id
  and t1.hiduke >= t2.hiduke
```
ここでhidukeに不等号（t1.hiduke >= t2.hiduke)を使用することで
対象行のsaledateよりも小さいデータを列挙可能にしている。
これを最後にsumすれば日ごとの累計値を求めることができる。

### t3テーブルの説明
```
inner join store as t3 on
  t1.store_id = t3.store_id
```
親テーブルとinner joinすることで抽出したデータの属性値を表示可能にしている。

### 外側のselect句
t1,t2,t3がすべてinner joinされた状態でデータを表示するための最後の選択を行う。
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
それを集計、ついでに接頭辞「r_」を付与している。

1)group_typeによってここの列は変化する。
```
    ,t1.sale_month
    ,t1.sale_day
```
   
### 外側のgroup句
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
1)group_typeによってここの列は変化する。
```
    ,t1.sale_month
    ,t1.sale_day
```
