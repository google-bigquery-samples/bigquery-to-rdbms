#standardSQL
SELECT PARSE_DATE('%Y%m%d', '20170714') AS order_date
     , order_category
     , COUNT(1) AS order_count
  FROM `dwprj1.ods3.orders_20*`
 WHERE _TABLE_SUFFIX = SUBSTR('20170714', 3)
 GROUP BY 1, 2
