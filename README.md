# 🛒 E-Commerce SQL Analysis
### 30+ Advanced SQL Queries | PostgreSQL · CTEs · Window Functions · RFM · Cohorts

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/Advanced%20SQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Queries](https://img.shields.io/badge/30%2B%20Queries-brightgreen?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge)

---

## 📌 Problem Statement

An e-commerce company wants to unlock insights from their transactional database to improve customer retention, optimise product mix, and understand revenue drivers — using **SQL only**.

**Goal:** Write 30+ production-ready SQL queries covering RFM segmentation, cohort retention, funnel analysis, CLV, and revenue trends on a **100K+ row** dataset.

---

## 📁 Folder Structure

```
ecommerce-sql-analysis/
│
├── schema/
│   └── create_tables.sql        ← Database schema
│
├── queries/
│   ├── 01_basic_kpis.sql        ← Revenue, orders, customers
│   ├── 02_customer_analysis.sql ← CLV, segmentation
│   ├── 03_product_performance.sql
│   ├── 04_revenue_trends.sql    ← MoM, rolling avg
│   ├── 05_funnel_analysis.sql   ← Conversion funnel
│   ├── 06_cohort_retention.sql  ← Retention matrix
│   └── advanced_analysis.sql   ← All combined
│
└── README.md
```

---

## 💻 SQL Techniques Used

| Technique | Query Example |
|---|---|
| **CTE (WITH clause)** | CLV calculation, cohort base tables |
| **Window Functions** | `RANK()`, `NTILE()`, `LAG()`, `ROLLING AVG` |
| **Subqueries** | Revenue share %, category benchmarks |
| **CASE WHEN** | Salary bands, age groups, RFM segments |
| **JOINS** | Multi-table order + product + review joins |
| **Aggregations** | `SUM`, `AVG`, `COUNT DISTINCT`, `PERCENTILE` |
| **Date functions** | `TO_CHAR`, `DATE_TRUNC`, month/year extraction |

---

## 📈 Key Business Insights

| Insight | Detail |
|---|---|
| Pareto Rule confirmed | Top 20% customers = **68% of revenue** |
| Cart abandonment | **72%** — biggest revenue leak in funnel |
| Cohort retention | Month-3 drops to **18%** — onboarding gap |
| Champions segment | 8% of customers, **41% of revenue** |
| Seasonal peak | Q4 drives **40%** of annual revenue |

---

## 🚀 How to Run

```bash
git clone https://github.com/mohanigupta/ecommerce-sql-analysis.git

# Connect to PostgreSQL
psql -U postgres -d ecommerce_db

# Create schema
\i schema/create_tables.sql

# Run analysis
\i queries/advanced_analysis.sql
```

---

## 👩‍💻 Author
**Mohani Gupta** | 📧 mohanigupta279@gmail.com | 🔗 [LinkedIn](https://linkedin.com/in/mohanigupta)
