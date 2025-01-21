## 1. Perbandingan Pendapatan Kimia Farma dari tahun ke tahun
SELECT
  EXTRACT(YEAR FROM date) AS Year,
  SUM(nett_sales) AS Total_Sales,
  SUM(nett_profit) AS Total_Profit,
  COUNT(transaction_id) AS Total_Transaksi
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1
ORDER BY 1;

## 2. Top 10 Total transaksi cabang provinsi
SELECT 
  provinsi,
  COUNT(transaction_id) AS Total_Transaksi
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

## 3. Top 10 Nett sales cabang provinsi
SELECT 
  provinsi,
  SUM(nett_sales) AS Total_Sales
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

## 4. Top 5 Cabang Dengan Rating Tertinggi, namun Rating Transaksi Terendah
SELECT 
  DISTINCT branch_id,
  branch_name,
  kota,
  branch_rating,
  transaction_rating
FROM `kimia_farma.kf_tabel_analisa`
ORDER BY 4 DESC, 5 ASC
LIMIT 5;

## 5. Stock 
WITH stock AS (SELECT 
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
  month,
  product_name,
  ROUND(AVG(product),0) AS avg_product_sold_monthly
FROM stock
GROUP BY 1,2
ORDER BY 1,3 DESC
LIMIT 10;


## 6. produk dengan total order 3 tertinggi tiap bulan
WITH total AS (SELECT 
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
  month,
  product_name,
  total_transaction 
FROM total
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY month ORDER BY total_transaction DESC
) <= 3
ORDER BY month;


## 7. Average diskon per bulan mempengaruhi volume penjualan per bulan?
SELECT 
  EXTRACT(YEAR FROM date) AS year,
  EXTRACT(MONTH FROM date) AS month,
  ROUND(AVG(discount_percentage),4) AS avg_discount,
  COUNT(*) AS sales_volume
FROM `kimia_farma.kf_tabel_analisa`
GROUP BY 1,2
ORDER BY 1,2
