# 📊 Vendor Sales & Inventory Performance Analysis (SQL + Power BI)

This project analyzes large-scale retail **sales, purchase, and inventory data** using **SQL for data processing** and **Power BI for visualization and business insights**.

The goal is to convert raw transactional data into **actionable insights** for vendor performance, profitability, and inventory optimization.

---

## 🚀 Dataset Overview

| Table Name | Description | Approx. Rows |
|------------|------------|--------------|
| `sales` | Retail sales transactions | 12.8+ million |
| `inventory_purchases` | Inventory purchase records | 2.3+ million |
| `vendor_invoices` | Freight & invoice details | 5,500+ |
| `purchase_price` | Vendor pricing reference | — |

The raw CSV files were loaded into a SQL database and transformed for analytics.

---

## 🛠️ Tools & Technologies

### Data Engineering & Analysis
- **SQL (PostgreSQL style)**
- CTEs & subqueries
- Window functions (`RANK`)
- Indexing for performance optimization
- Large-scale joins and aggregations

### Data Visualization
- **Power BI**
- DAX measures
- KPI cards & interactive dashboards
- Vendor & brand-level analysis

---

## 📌 Project Workflow

1. Loaded Kaggle dataset into SQL database
2. Designed relational tables for sales, purchases, invoices, and pricing
3. Optimized queries using indexing on large fact tables
4. Integrated freight costs into total purchase cost
5. Built a **vendor-level aggregated summary table**
6. Calculated profit, margin, turnover, and unsold inventory
7. Imported cleaned data into Power BI
8. Created interactive dashboards for business users

---

## 📈 Business Metrics Calculated

- Total Sales Amount
- Total Purchase Cost (including freight)
- Gross Profit & Profit Margin (%)
- Unsold Inventory Value
- Inventory Turnover Ratio
- Bulk vs Low-volume vendor classification

---

## 📊 Power BI Dashboard Highlights

- Top & Bottom Vendors by Profit
- Vendor-wise Sales vs Cost comparison
- Brand performance analysis
- Identification of low-performing products
- Interactive slicers for vendor and brand

---

## 🔍 Key Analytical Insights

- Identified **top 10 profit-generating vendors**
- Flagged vendors with **high cost but low sales**
- Highlighted brands with **low margin and weak demand**
- Reduced inventory risk by detecting unsold stock

---

## ⚡ Performance Optimization

- Indexed large transactional tables
- Used pre-aggregated SQL tables to reduce Power BI load
- Improved dashboard responsiveness on large datasets

---
