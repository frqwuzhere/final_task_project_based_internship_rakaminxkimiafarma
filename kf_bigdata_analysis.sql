-- Tabel Analisa
CREATE TABLE `rakamin-kf-analytics-447401.kimia_farma.kf_tabel_analisa`  AS 
-- CREATE syntax untuk membuat tabel
SELECT 
  final_transaction.transaction_id,
  final_transaction.date,
  final_transaction.branch_id,
  branch.branch_name,
  branch.kota,
  branch.provinsi,
  branch.rating AS branch_rating,
  final_transaction.customer_name,
  final_transaction.product_id,
  product.product_name,
  final_transaction.price AS actual_price,
  final_transaction.discount_percentage,
  CASE -- menambah kondisi untuk gross laba persentase
    WHEN final_transaction.price  500000 THEN 0.3
    WHEN final_transaction.price  300000 THEN 0.25
    WHEN final_transaction.price  100000 THEN 0.2
    WHEN final_transaction.price  50000 THEN 0.15
    ELSE 0.1
  END AS presentase_gross_laba,
  final_transaction.price - (final_transaction.price * final_transaction.discount_percentage) AS nett_sales,
  -- nett sales, dari harga - harga * diskon
  CASE -- menambahkan kondisi untuk nett profit 
    WHEN final_transaction.price  500000 THEN ROUND(final_transaction.price  (0.3 - final_transaction.discount_percentage),0)
    WHEN final_transaction.price  300000 THEN ROUND(final_transaction.price  (0.25 - final_transaction.discount_percentage),0)
    WHEN final_transaction.price  100000 THEN ROUND(final_transaction.price  (0.2 - final_transaction.discount_percentage),0)
    WHEN final_transaction.price  50000 THEN ROUND(final_transaction.price  (0.15 - final_transaction.discount_percentage),0)
    ELSE ROUND(final_transaction.price  (0.1 - final_transaction.discount_percentage),0)
  END AS nett_profit,
  final_transaction.rating AS transaction_rating
FROM `rakamin-kf-analytics-447401.kimia_farma.kf_final_transaction` AS final_transaction
LEFT JOIN `rakamin-kf-analytics-447401.kimia_farma.kf_product` AS product -- left join produk ke transaksi
ON final_transaction.product_id = product.product_id
LEFT JOIN `rakamin-kf-analytics-447401.kimia_farma.kf_kantor_cabang` AS branch -- left join branch ke transaksi
ON final_transaction.branch_id = branch.branch_id;





-- 1. Perbandingan Pendapatan Kimia Farma dari tahun ke tahun
SELECT
  EXTRACT(YEAR FROM date) AS Year, -- mengambil tahun dari date
  SUM(nett_sales) AS Total_Sales, -- menjumlah nett_sales
  SUM(nett_profit) AS Total_Profit, -- menjumlah nett_profit
  COUNT(transaction_id) AS Total_Transaksi -- menghitung transaksi
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1
ORDER BY 1;

-- 2. Top 10 Total transaksi cabang provinsi
SELECT 
  provinsi, 
  COUNT(transaction_id) AS Total_Transaksi -- menghitung transaksi setiap provinsi
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1 -- group sesuai provinsi
ORDER BY 2 DESC
LIMIT 10;

-- 3. Top 10 Nett sales cabang provinsi
SELECT 
  provinsi,
  SUM(nett_sales) AS Total_Sales -- menjumlahkan nett_sales tiap provinsi
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- 4. Top 5 Cabang Dengan Rating Tertinggi, namun Rating Transaksi Terendah
SELECT 
  DISTINCT branch_id,
  branch_name,
  kota,
  branch_rating,
  transaction_rating
FROM `kimia_farma.kf_tabel_analisa`
ORDER BY 4 DESC, 5 ASC -- mengurutkan berdasarkan 4 (branch_rating) secara descending, lalu mengurutkan berdasarkan 5 (transaction_rating secara) ascending
LIMIT 5;

-- 5. Stock 
WITH stock AS (SELECT 
-- kita cari jumlah penjualan setiap produk di setiap branch
  EXTRACT(MONTH FROM s.date) AS month,
  s.branch_id,
  inventory.product_name,
  COUNT(inventory.product_name) AS product
FROM `kimia_farma.kf_final_transaction` as s
  JOIN `kimia_farma.kf_inventory` AS inventory
  ON s.branch_id = inventory.branch_id
  AND s.product_id = inventory.product_id
GROUP BY 1,2,3
ORDER BY 1,2
)

SELECT 
-- kita cari rata" setiap produk untuk setiap bulannya
  month,
  product_name,
  ROUND(AVG(product),0) AS avg_product_sold_monthly
FROM stock
GROUP BY 1,2
ORDER BY 1,3 DESC
LIMIT 10;


-- 6. produk dengan total order 3 tertinggi tiap bulan
WITH total AS (SELECT 
-- mencari produk dengan total transaksi tertinggi tiap bulannya dengan CTE
  EXTRACT(MONTH FROM final.date) AS month,
  inventory.product_name,
  COUNT(*) AS total_transaction
FROM `kimia_farma.kf_final_transaction` AS final
JOIN `kimia_farma.kf_inventory` AS inventory
ON final.product_id = inventory.product_id
AND final.branch_id = inventory.branch_id
GROUP BY 1,2
ORDER BY 1)

SELECT
-- lalu tinggak pilih yang ada di top 3
  month,
  product_name,
  total_transaction 
FROM total
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY month ORDER BY total_transaction DESC
) <= 3
ORDER BY month;


-- 7. Average diskon per bulan mempengaruhi volume penjualan per bulan?
SELECT 
-- mencari rata-rata diskon pertahun dan perbulan, apakah mempengaruhi?
  EXTRACT(YEAR FROM date) AS year,
  EXTRACT(MONTH FROM date) AS month,
  ROUND(AVG(discount_percentage),4) AS avg_discount,
  COUNT(*) AS sales_volume
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1,2
ORDER BY 1,2
