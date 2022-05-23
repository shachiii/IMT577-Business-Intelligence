USE SCHEMA PUBLIC;

-- Q1

-- Daily target comparison
CREATE OR REPLACE SECURE VIEW DAILY_SALES_TARGET
AS
    with DAILY_SALES AS (
    SELECT DISTINCT
        DIM_STORE.STORENUMBER,
        DIM_DATE.DATE_PKEY,
        DIM_DATE.YEAR,
        --FACT_SRCSALESTARGET.SALESTARGETAMOUNT AS TARGETAMOUNT,
        SUM(FACT_SALESACTUAL.SALEAMOUNT) AS SALESAMOUNT
    FROM FACT_SALESACTUAL
    INNER JOIN DIM_DATE
    ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
    INNER JOIN DIM_STORE
    ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
    WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8
    GROUP BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY, DIM_DATE.YEAR
    ORDER BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY),

    -- create view for target
    DAILY_TARGET AS (
        SELECT DISTINCT
        DIM_STORE.STORENUMBER,
        DIM_DATE.DATE_PKEY,
        DIM_DATE.YEAR,
        FACT_SRCSALESTARGET.SALESTARGETAMOUNT/365 AS TARGETAMOUNT
    FROM FACT_SRCSALESTARGET
    INNER JOIN DIM_DATE
    ON FACT_SRCSALESTARGET.DIMTARGETDATEID = DIM_DATE.DATE_PKEY
    INNER JOIN DIM_STORE
    ON FACT_SRCSALESTARGET.DIMSTOREID = DIM_STORE.DIMSTOREID
    WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8
    ORDER BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY)

SELECT DISTINCT DAILY_SALES.STORENUMBER,
    DAILY_SALES.YEAR,
    DAILY_SALES.DATE_PKEY,
    DAILY_TARGET.TARGETAMOUNT,
    DAILY_SALES.SALESAMOUNT,
    (DAILY_SALES.SALESAMOUNT - DAILY_TARGET.TARGETAMOUNT) AS SALES_DIFFERENCE,
    CASE 
        WHEN DAILY_SALES.SALESAMOUNT > DAILY_TARGET.TARGETAMOUNT THEN 'YES'
        ELSE 'NO'
    END AS TARGETMET
FROM DAILY_SALES
LEFT OUTER JOIN DAILY_TARGET ON DAILY_SALES.DATE_PKEY = DAILY_TARGET.DATE_PKEY
WHERE DAILY_SALES.STORENUMBER = DAILY_TARGET.STORENUMBER
ORDER BY DAILY_SALES.STORENUMBER, DAILY_SALES.DATE_PKEY;

SELECT * FROM DAILY_SALES_TARGET
-- Annual target comparison
CREATE OR REPLACE SECURE VIEW ANNUAL_SALES_TARGET
AS
    with DAILY_SALES AS (
    SELECT DISTINCT
        DIM_STORE.STORENUMBER,
        DIM_DATE.DATE_PKEY,
        DIM_DATE.YEAR,
        --FACT_SRCSALESTARGET.SALESTARGETAMOUNT AS TARGETAMOUNT,
        SUM(FACT_SALESACTUAL.SALEAMOUNT) AS SALESAMOUNT
    FROM FACT_SALESACTUAL
    INNER JOIN DIM_DATE
    ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
    INNER JOIN DIM_STORE
    ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
    WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8
    GROUP BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY, DIM_DATE.YEAR
    ORDER BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY),

    -- create view for target
    DAILY_TARGET AS (
        SELECT DISTINCT
        DIM_STORE.STORENUMBER,
        DIM_DATE.DATE_PKEY,
        DIM_DATE.YEAR,
        FACT_SRCSALESTARGET.SALESTARGETAMOUNT/365 AS TARGETAMOUNT
FROM FACT_SRCSALESTARGET
INNER JOIN DIM_DATE
ON FACT_SRCSALESTARGET.DIMTARGETDATEID = DIM_DATE.DATE_PKEY
INNER JOIN DIM_STORE
ON FACT_SRCSALESTARGET.DIMSTOREID = DIM_STORE.DIMSTOREID
WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8
ORDER BY DIM_STORE.STORENUMBER, DIM_DATE.DATE_PKEY)
SELECT STORENUMBER,
    YEAR,
    MAX(DATE_PKEY) AS DATE_,
    SUM(TARGETAMOUNT) AS ANNUALTARGET,
    SUM(SALESAMOUNT) AS SALES_TO_DATE,
    SALES_TO_DATE - ANNUALTARGET AS SALES_DIFFERENCE,
    CASE 
        WHEN SALES_TO_DATE > ANNUALTARGET THEN 'YES'
        ELSE 'NO'
    END AS TARGETMET
FROM DAILY_SALES_TARGET
GROUP BY STORENUMBER, YEAR
ORDER BY STORENUMBER, YEAR;

select * from BONUS_RECOMMENDATION
-- Q2
-- Bonus recommendation
CREATE OR REPLACE SECURE VIEW BONUS_RECOMMENDATION
AS
SELECT DISTINCT
    YEAR, 
    STORENUMBER,
    PRODUCTTYPE,
    SALE, PROFIT,
    SUM(SALE) OVER (PARTITION BY YEAR) AS TOTAL_SALE,
    (SALE/TOTAL_SALE) AS PROPORTION,
ROUND
(
CASE WHEN YEAR = 2013 THEN 500000*(SALE/TOTAL_SALE)
    WHEN YEAR = 2014 THEN 400000*(SALE/TOTAL_SALE)
END,2) AS BONUS_PROPORTION
FROM
(
SELECT DISTINCT 
    Dim_Date.Year, 
    Dim_Store.STORENUMBER,
    Dim_Product.ProductType,
    SUM(Fact_SalesActual.SALEAMOUNT) AS SALE, 
    SUM(FAct_SalesActual.SALETOTALPROFIT) AS PROFIT
FROM FACT_SALESACTUAL 
INNER JOIN DIM_STORE ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
INNER JOIN DIM_PRODUCT ON FACT_SALESACTUAL.DIMPRODUCTID = DIM_PRODUCT.DIMPRODUCTID
INNER JOIN DIM_DATE ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
WHERE DIM_PRODUCT.PRODUCTTYPE LIKE '%Casual' AND DIM_STORE.STORENUMBER IN (5,8)
AND DIM_DATE.YEAR||DIM_DATE.MONTH_NUM_IN_YEAR NOT IN (201411, 201412)  
GROUP BY DIM_DATE.Year, DIM_STORE.STORENUMBER, DIM_PRODUCT.PRODUCTTYPE
)
ORDER BY YEAR, STORENUMBER;

--Q3
-- Sales by day of week
CREATE OR REPLACE SECURE VIEW SALES_BY_WEEK
AS 
SELECT DISTINCT 
DIM_STORE.STORENUMBER,
DIM_DATE.DAY_NUM_IN_WEEK,
DIM_DATE.DAY_NAME,
SUM(FACT_SALESACTUAL.SALEAMOUNT) AS SALEAMOUNT,
SUM(FACT_SALESACTUAL.SALEQUANTITY) AS SALEQUANTITY
FROM FACT_SALESACTUAL
INNER JOIN DIM_DATE
ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
INNER JOIN DIM_STORE
ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8 
GROUP BY DIM_STORE.STORENUMBER,
DIM_DATE.DAY_NUM_IN_WEEK, DIM_DATE.DAY_NAME
ORDER BY DIM_STORE.STORENUMBER, DIM_DATE.DAY_NUM_IN_WEEK;

-- Sales by day of week based on product category
CREATE OR REPLACE SECURE VIEW SALES_BY_WEEK_PER_PRODUCT
AS 
SELECT DISTINCT 
DIM_STORE.STORENUMBER,
DIM_DATE.DAY_NUM_IN_WEEK,
DIM_DATE.DAY_NAME,
DIM_PRODUCT.PRODUCTCATEGORY,
SUM(FACT_SALESACTUAL.SALEAMOUNT) AS SALEAMOUNT,
SUM(FACT_SALESACTUAL.SALEQUANTITY) AS SALEQUANTITY
FROM FACT_SALESACTUAL
INNER JOIN DIM_DATE
ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
INNER JOIN DIM_STORE
ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
INNER JOIN DIM_PRODUCT
ON FACT_SALESACTUAL.DIMPRODUCTID = DIM_PRODUCT.DIMPRODUCTID
WHERE DIM_STORE.STORENUMBER = 5 OR DIM_STORE.STORENUMBER = 8 
GROUP BY DIM_STORE.STORENUMBER,
DIM_DATE.DAY_NUM_IN_WEEK, DIM_DATE.DAY_NAME,
DIM_PRODUCT.PRODUCTCATEGORY
ORDER BY DIM_STORE.STORENUMBER, DIM_PRODUCT.PRODUCTCATEGORY, DIM_DATE.DAY_NUM_IN_WEEK;

-- Q4
CREATE OR REPLACE SECURE VIEW STORE_LOCATION
AS
SELECT DISTINCT
    DIM_DATE.YEAR,
    DIM_LOCATION.STATE_PROVINCE, 
    X.STORE_COUNT,
  SUM(FACT_SALESACTUAL.SALEQUANTITY) AS QUANTITY, 
  SUM(FACT_SALESACTUAL.SALEAMOUNT) AS SALE, 
  SUM(FACT_SALESACTUAL.SALETOTALPROFIT) AS PROFIT
FROM FACT_SALESACTUAL
INNER JOIN DIM_STORE ON FACT_SALESACTUAL.DIMSTOREID = DIM_STORE.DIMSTOREID
INNER JOIN DIM_LOCATION ON DIM_STORE.DIMLOCATIONID = DIM_LOCATION.DIMLOCATIONID
INNER JOIN DIM_DATE ON FACT_SALESACTUAL.DIMSALEDATEID = DIM_DATE.DATE_PKEY
INNER JOIN
(
SELECT DIM_LOCATION.STATE_PROVINCE, 
COUNT(DIM_STORE.STORENUMBER) AS STORE_COUNT
FROM DIM_STORE
INNER JOIN DIM_LOCATION ON DIM_STORE.DIMLOCATIONID = DIM_LOCATION.DIMLOCATIONID
GROUP BY DIM_LOCATION.STATE_PROVINCE
) X ON DIM_LOCATION.STATE_PROVINCE = X.STATE_PROVINCE
GROUP BY DIM_DATE.YEAR,  
DIM_LOCATION.STATE_PROVINCE, X.STORE_COUNT
ORDER BY DIM_DATE.YEAR, DIM_LOCATION.STATE_PROVINCE;

--Creating views for all the dimension and fact tables

--Channel
CREATE OR REPLACE SECURE VIEW CHANNEL_VIEW
AS
SELECT 
    DIMCHANNELID,
    SOURCECHANNELID,
    SOURCECHANNELCATEGORYID,
    CHANNELNAME,
    CHANNELCATEGORY
FROM DIM_CHANNEL;

--Customer
CREATE OR REPLACE SECURE VIEW CUSTOMER_VIEW
AS
SELECT
    DIMCUSTOMERID,
    DIMLOCATIONID,
    CUSTOMERID,
    CUSTOMERFULLNAME,
    CUSTOMERFIRSTNAME,
    CUSTOMERLASTNAME,
    CUSTOMERGENDER,
    EMAILADDRESS,
    PHONENUMBER
FROM DIM_CUSTOMER;

select * from dim_customer
-- Reseller 
CREATE OR REPLACE SECURE VIEW RESELLER_VIEW
AS
SELECT
    DIMRESELLERID,
    DIMLOCATIONID,
    RESELLERID,
    RESELLERNAME,
    CONTACTNAME,
    PHONENUMBER,
    EMAIL
FROM DIM_RESELLER;

-- Store
CREATE OR REPLACE SECURE VIEW STORE_VIEW
AS
SELECT
    DIMSTOREID,
    DIMLOCATIONID,
    SOURCESTOREID,
    STORENUMBER,
    STOREMANAGER
FROM DIM_STORE;

SELECT * FROM DIM_LOCATION;

-- Location
CREATE OR REPLACE SECURE VIEW LOCATION_VIEW
AS
SELECT
    DIMLOCATIONID,
    POSTALCODE,
    ADDRESS,
    CITY,
    STATE_PROVINCE,
    COUNTRY
FROM DIM_LOCATION;

SELECT * FROM DIM_PRODUCT;

-- Product
CREATE OR REPLACE SECURE VIEW PRODUCT_VIEW
AS
SELECT
    DIMPRODUCTID,
    SOURCEPRODUCTID,
    SOURCEPRODUCTTYPEID,
    SOURCEPRODUCTCATEGORYID,
    PRODUCTNAME,
    PRODUCTTYPE,
    PRODUCTRETAILPRICE,
    PRODUCTWHOLESALEPRICE,
    PRODUCTCOST,
    PRODUCTRETAILPROFIT,
    PRODUCTWHOLESALEUNIT,
    PRODUCTPROFITMARGINUNITPERCENT
FROM DIM_PRODUCT;

-- Date
CREATE OR REPLACE SECURE VIEW Date_View
AS
SELECT DATE_PKEY,
    DATE,
	FULL_DATE_DESC,
	DAY_NUM_IN_WEEK,
	DAY_NUM_IN_MONTH,
	DAY_NUM_IN_YEAR,
	DAY_NAME,
	DAY_ABBREV,
	WEEKDAY_IND,
	US_HOLIDAY_IND,
	_HOLIDAY_IND,
	MONTH_END_IND,
	WEEK_BEGIN_DATE_NKEY,
	WEEK_BEGIN_DATE,
	WEEK_END_DATE_NKEY,
	WEEK_END_DATE,
	WEEK_NUM_IN_YEAR,
	MONTH_NAME,
	MONTH_ABBREV,
	MONTH_NUM_IN_YEAR,
	YEARMONTH,
	QUARTER,
	YEARQUARTER,
	YEAR,
	FISCAL_WEEK_NUM,
	FISCAL_MONTH_NUM,
	FISCAL_YEARMONTH,
	FISCAL_QUARTER,
	FISCAL_YEARQUARTER,
	FISCAL_HALFYEAR,
	FISCAL_YEAR,
	SQL_TIMESTAMP,
	CURRENT_ROW_IND,
	EFFECTIVE_DATE,
	EXPIRATION_DATE 
FROM DIM_DATE;

-- Fact product sales target
CREATE OR REPLACE SECURE VIEW PRODUCTSALESTARGET_VIEW
AS
SELECT
    DIMPRODUCTID,
    DIMTARGETDATEID,
    PRODUCTTARGETSALESQUANTITY
FROM FACT_PRODUCTSALESTARGET;

-- Fact sales actual
CREATE OR REPLACE SECURE VIEW SALESACTUAL_VIEW
AS
SELECT
    DIMPRODUCTID,
    DIMSTOREID,
    DIMRESELLERID,
    DIMCUSTOMERID,
    DIMCHANNELID,
    DIMSALEDATEID,
    DIMLOCATIONID,
    SOURCESALESHEADERID,
    SOURCESALESDETAILID,
    SALEAMOUNT,
    SALEQUANTITY,
    SALEUNITPRICE,
    SALEEXTENDEDCOST,
    SALETOTALPROFIT
FROM FACT_SALESACTUAL;

-- Fact src sales target
CREATE OR REPLACE SECURE VIEW SRCSALESTARGET_VIEW
AS
SELECT
    DIMSTOREID,
    DIMRESELLERID,
    DIMCHANNELID,
    DIMTARGETDATEID,
    SALESTARGETAMOUNT
FROM FACT_SRCSALESTARGET;