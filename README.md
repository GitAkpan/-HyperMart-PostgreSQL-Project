# -HyperMart-PostgreSQL-Project

Project Overview

HyperMart Nigeria Ltd. is a multi-department retail chain operating across nine Nigerian cities. This project simulates the work of a data analyst tasked with replacing manual Excel reporting with a fully functional PostgreSQL analytics layer.

The project covers 20 SQL problems mapped to real business needs from department revenue reporting to automated audit triggers using a realistic 500-row transactional dataset.

🗂️ Repository Structure

hypermart-postgresql/
├── dataset/
│   └── HyperMart_Dataset_500.xlsx       # 500-row Excel dataset (5 tables)
├── docs/
│   └── HyperMart_PostgreSQL_Expanded.docx  # Full problem & solution guide (20 problems)
├── sql/
│   ├── 01_create_tables.sql             # DDL schema creation
│   ├── 02_insert_data.sql               # Sample data all 5 tables
│   ├── 03_joins_aggregations.sql        # Problems P1–P5
│   ├── 04_ctes_subqueries.sql           # Problems P6–P10
│   ├── 05_window_functions.sql          # Problems P11–P15
│   └── 06_procedures_triggers.sql       # Problems P16–P20
└── README.md


Database Schema

departments ─ products ─ order_items ─ orders ─ customers

TableRowsDescriptiondepartments4Four product divisionsproducts15SKUs across all departmentscustomers100Loyalty members — 9 Nigerian citiesorders200Transaction headers with status trackingorder_items500Line items: product × quantity × price

Entity Relationships


products.dept_id - departments.dept_id
orders.customer_id - customers.customer_id
order_items.order_id - orders.order_id
order_items.product_id - products.product_id



Problem Index

Area A — JOINs & Aggregations (P1–P5)

#ProblemKey ConceptsDifficultyP1Product Revenue ReportLEFT JOIN, COALESCE, GROUP BY★P2City Sales SummaryMulti-JOIN, conditional ON filter, HAVING,P3Department Revenue ShareJOIN + nested SUM OVER ()★★P4Customer Order HistoryMulti-table JOIN, COUNT DISTINCT★P5Cancelled Order ImpactDATE_TRUNC, WHERE filter, GROUP BY

Area B — CTEs & Subqueries (P6–P10)

#ProblemKey ConceptsDifficultyP6Above-Average SpendersCTE, scalar subquery, AVG★★P7Top Product Per DepartmentChained CTEs, MAX join pattern★★★P8Department Price BenchmarkCorrelated subquery★★P9Monthly Revenue TrendDATE_TRUNC, TO_CHAR, CTE + window★★P10Repeat BuyersCTE, COUNT, HAVING

Area C — Window Functions (P11–P15)

#ProblemKey ConceptsDifficultyP11Running Revenue TotalSUM() OVER (ORDER BY)★★P12Customer Spend RankRANK(), DENSE_RANK(), PERCENT_RANK()★★P13Product Sales PercentileNTILE(4), CASE WHEN★★★P14Month-over-Month GrowthLAG(), NULLIF(), growth %★★★P15Top 3 Products Per DepartmentROW_NUMBER() OVER (PARTITION BY)★★★

Area D — Stored Procedures & Functions (P16–P20)

#ProblemKey ConceptsDifficultyP16Customer Spend FunctionPL/pgSQL FUNCTION, SELECT INTO★★P17Restock Product ProcedurePROCEDURE, RAISE EXCEPTION, P18Order Summary FunctionRETURNS TABLE, RETURN QUERY★★★P19Bulk Status UpdateGET DIAGNOSTICS, ROW_COUNT, INTERVAL★★★P20Price Change Audit TriggerTRIGGER, NEW/OLD, audit log table★★★


How to Run
Prerequisites
PostgreSQL 15+ (tested on PostgreSQL 18)
pgAdmin 4 or psql


Setup

Step 1 — Create the database

CREATE DATABASE hypermart;

Step 2 — Run the schema

bashpsql -U postgres -d hypermart -f sql/01_create_tables.sql

Step 3 — Load the data

bashpsql -U postgres -d hypermart -f sql/02_insert_data.sql

Step 4 — Run any query file

bashpsql -U postgres -d hypermart -f sql/03_joins_aggregations.sql

Or open the .sql files directly in pgAdmin Query Tool and execute them one by one.


Export each sheet as CSV (File → Save As → CSV UTF-8)
In pgAdmin: right-click each table → Import/Export Data → select CSV → Header: Yes



Key SQL Concepts Demonstrated

ConceptWhere usedLEFT JOIN with COALESCEP1, P4, P6, P12JOIN filter in ON vs WHEREP2, P4, P6DATE_TRUNC + TO_CHARP5, P9, P14CTE referenced multiple timesP6, P9Chained CTEsP7, P12, P13, P15Correlated subqueryP8SUM() OVER () grand totalP3, P11RANK() / DENSE_RANK()P12NTILE(n) performance bandsP13LAG() period-over-periodP14ROW_NUMBER() PARTITION BYP15PL/pgSQL functionP16, P18PROCEDURE + RAISE EXCEPTIONP17, P19RETURNS TABLE + RETURN QUERYP18TRIGGER + NEW / OLDP20


Business Context

StakeholderProblem(s)CEOP1, P3, P9, P14 — revenue, department share, monthly trendHead of SalesP4, P6, P10, P12 — customer spend, VIP tier, repeat buyersInventory ManagerP7, P13, P17 — top products, stock quartiles, restockMarketingP2, P8, P15 — city summary, price benchmark, top 3 per deptFinanceP3, P5, P11 — dept share, cancelled impact, running totalOperationsP19, P20 — stale order cleanup, price audit log



Database: PostgreSQL 18
GUI: pgAdmin 4
Dataset: Microsoft Excel (.xlsx) — 500 rows across 5 tables
Language: SQL + PL/pgSQL



File Guide

FileWhat it containssql/01_create_tables.sqlAll 5 CREATE TABLE statements with constraints and foreign keyssql/02_insert_data.sqlINSERT statements for all 500 rowssql/03_joins_aggregations.sqlP1–P5 — revenue reports, city summaries, department sharesql/04_ctes_subqueries.sqlP6–P10 — VIP customers, top products, monthly trendsql/05_window_functions.sqlP11–P15 — running totals, rankings, LAG, NTILEsql/06_procedures_triggers.sqlP16–P20 — functions, procedures, audit triggerdataset/HyperMart_Dataset_500.xlsxRaw dataset — import into PostgreSQL via CSV or Pythondocs/HyperMart_PostgreSQL_Expanded.docxFull 45-page problem & solution document


Author

Akpan Abasifreke
Data Analyst · SQL · Power BI · Python · Excel
