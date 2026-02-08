-- ==============================
-- RAW DATA TABLES
-- ==============================

CREATE TABLE sales (
    InventoryId VARCHAR(50),
    Store INT,
    Brand INT,
    Description TEXT,
    Size VARCHAR(20),
    SalesQuantity INT,
    SalesDollars NUMERIC(12,2),
    SalesPrice NUMERIC(10,2),
    SalesDate DATE,
    Volume NUMERIC(10,2),
    Classification INT,
    ExciseTax NUMERIC(10,2),
    VendorNo INT,
    VendorName VARCHAR(100)
);

CREATE TABLE inventory_purchases (
    InventoryId VARCHAR(50),
    Store INT,
    Brand INT,
    Description VARCHAR(255),
    Size VARCHAR(50),
    VendorNumber INT,
    VendorName VARCHAR(255),
    PONumber INT,
    PODate DATE,
    ReceivingDate DATE,
    InvoiceDate DATE,
    PayDate DATE,
    PurchasePrice NUMERIC(10,2),
    Quantity INT,
    Dollars NUMERIC(12,2),
    Classification INT
);

CREATE TABLE vendor_invoices (
    VendorNumber INT,
    VendorName TEXT,
    InvoiceDate DATE,
    PONumber INT,
    PODate DATE,
    PayDate DATE,
    Quantity INT,
    Dollars NUMERIC(12,2),
    Freight NUMERIC(12,2),
    Approval TEXT
);

CREATE TABLE purchase_price (
    Brand INT,
    Description TEXT,
    Price NUMERIC(10,2),
    Size VARCHAR(50),
    Volume VARCHAR(50),
    Classification INT,
    PurchasePrice NUMERIC(10,2),
    VendorNumber INT,
    VendorName TEXT
);

-- ==============================
-- DATA VOLUME
-- ==============================
-- sales                : ~12.8 million rows
-- inventory_purchases  : ~2.3 million rows
-- vendor_invoices      : ~5,500 rows

-- ==============================
-- PERFORMANCE OPTIMIZATION
-- ==============================

CREATE INDEX idx_sales_vendor_brand_desc
ON sales (VendorNo, Brand, Description);

CREATE INDEX idx_inventory_vendor_po
ON inventory_purchases (VendorNumber, PONumber);


-- ==============================
-- FINAL SUMMARY TABLE
-- ==============================

CREATE TABLE vendortable AS
WITH freighttable AS (
    SELECT
        vendornumber,
        ponumber,
        SUM(freight) AS total_freight
    FROM vendor_invoices
    GROUP BY vendornumber, ponumber
),

purchasetable AS (
    SELECT
        i.vendornumber,
        i.vendorname,
        i.brand,
        i.ponumber,
        i.description,
        pp.price AS actual_price,
        i.purchaseprice,
        SUM(i.quantity) AS purchasequantity,
        SUM(i.dollars) AS purchasedollars,
        COALESCE(f.total_freight, 0) AS total_freight
    FROM inventory_purchases i
    LEFT JOIN freighttable f
        ON i.vendornumber = f.vendornumber
       AND i.ponumber = f.ponumber
    LEFT JOIN purchase_price pp
        ON i.vendornumber = pp.vendornumber
       AND i.brand = pp.brand
       AND i.description = pp.description
    GROUP BY
        i.vendornumber,
        i.vendorname,
        i.brand,
        i.ponumber,
        i.description,
        i.purchaseprice,
        pp.price,
        f.total_freight
),

finalpurchase AS (
    SELECT
        vendornumber,
        vendorname,
        brand,
        description,
        actual_price,
        purchaseprice,
        SUM(purchasequantity) AS purchasequantity,
        SUM(purchasedollars) AS purchasedollars,
        SUM(purchasedollars + total_freight) AS total_cost
    FROM purchasetable
    GROUP BY
        vendornumber,
        vendorname,
        brand,
        description,
        purchaseprice,
        actual_price
),

salestable AS (
    SELECT
        vendorno,
        vendorname,
        brand,
        description,
        SUM(salesquantity) AS salequantity,
        SUM(salesquantity * salesprice) AS sales_amount
    FROM sales
    GROUP BY vendorno, vendorname, brand, description
)

SELECT
    fp.*,
    COALESCE(ss.salequantity, 0) AS salequantity,
    COALESCE(ss.sales_amount, 0) AS sales_amount
FROM finalpurchase fp
LEFT JOIN salestable ss
    ON fp.vendornumber = ss.vendorno
   AND fp.brand = ss.brand
   AND fp.description = ss.description
WHERE COALESCE(ss.salequantity, 0) > 0;

-- ==============================
-- BUSINESS METRICS
-- ==============================

ALTER TABLE vendortable
ADD COLUMN profit DECIMAL(18,2);

UPDATE vendortable
SET profit = sales_amount - purchasedollars;

ALTER TABLE vendortable
ADD COLUMN profitmargin DECIMAL(10,2);

UPDATE vendortable
SET profitmargin =
    CASE
        WHEN sales_amount = 0 THEN 0
        ELSE profit * 100.0 / sales_amount
    END;

ALTER TABLE vendortable
ADD COLUMN unsoldvalue DECIMAL(18,2) GENERATED ALWAYS AS (
    CASE
        WHEN purchasequantity > salequantity
        THEN (purchasequantity - salequantity) * purchaseprice
        ELSE 0
    END
) STORED;

ALTER TABLE vendortable
ADD COLUMN turnoverratio NUMERIC GENERATED ALWAYS AS (
    CASE
        WHEN purchasequantity = 0 THEN 0
        ELSE salequantity::NUMERIC / purchasequantity
    END
) STORED;

DELETE FROM vendortable WHERE profit < 0;

-- ==============================
-- Analytical Queries
-- ==============================
WITH vendor_metrics AS (
    SELECT
        vendorname,
        SUM(sales_amount) AS total_sales,
        SUM(total_cost) AS total_cost,
        SUM(profit) AS profit
    FROM vendortable
    GROUP BY vendorname
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY profit DESC) AS rank_desc,
        RANK() OVER (ORDER BY profit ASC) AS rank_asc
    FROM vendor_metrics
)
SELECT * FROM ranked
WHERE rank_desc <= 10 OR rank_asc <= 10
ORDER BY profit DESC;

SELECT
    brand,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS profit,
    ROUND(SUM(profit) * 100.0 / SUM(sales_amount), 2) AS profit_margin,
    SUM(salequantity) AS units_sold
FROM vendortable
GROUP BY brand
HAVING
    profit_margin < 10
    OR total_sales < 5000
    OR units_sold < 100
ORDER BY profit ASC;
