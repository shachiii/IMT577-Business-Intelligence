USE SCHEMA PUBLIC;


--Fact Product Sales Target
CREATE TABLE Fact_ProductSalesTarget
(
	DimProductID INT CONSTRAINT FK_DimProductID FOREIGN KEY REFERENCES Dim_Product(DimProductID),
    DimTargetDateID number(9) CONSTRAINT FK_DimTragetDateID FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY),
    ProductTargetSalesQuantity INTEGER NOT NULL
);

INSERT INTO Fact_ProductSalesTarget(
	DimProductID,
    DimTargetDateID,
    ProductTargetSalesQuantity
)
SELECT DISTINCT 
    Dim_Product.DimProductID,
    Dim_Date.DATE_PKEY,
    TargetDataProduct.Salesquantitytarget

FROM TargetDataProduct
INNER JOIN Dim_Date 
ON	TargetDataProduct.Year = Dim_Date.Year
INNER JOIN Dim_Product 
ON  TargetDataProduct.ProductID = Dim_Product.DimProductID
ORDER BY DimProductID, Date_Pkey ASC;

-- Fact Sales Target
CREATE OR REPLACE TABLE Fact_SRCSalesTarget (
    DimStoreID INTEGER CONSTRAINT FK_DimStore FOREIGN KEY REFERENCES Dim_Store (DimStoreID) NOT NULL,
    DimResellerID INTEGER CONSTRAINT FK_dimReseller FOREIGN KEY REFERENCES Dim_Reseller (DimResellerID) NOT NULL,
    DimChannelID INTEGER CONSTRAINT FK_dimChannel FOREIGN KEY REFERENCES Dim_Channel (DimChannelID) NOT NULL ,
    DimTargetDateID NUMBER(9) CONSTRAINT FK_DimTragetDateID FOREIGN KEY REFERENCES Dim_Date (DATE_PKEY),
    SalesTargetAmount INTEGER NOT NULL
    );


INSERT INTO Fact_SRCSalesTarget(
	DimStoreID,
	DimResellerID,
	DimChannelID,
	DimTargetDateID,
	SalesTargetAmount
)
SELECT DISTINCT
	NVL(Dim_Store.DimStoreID, -1) as StoreID,
	NVL(Dim_Reseller.DimResellerid, -1) as ResellerID,
	Dim_Channel.DimChannelID,
	Dim_Date.Date_Pkey,
	TargetDataChannel.TargetSalesAmount
FROM TargetDataChannel
LEFT JOIN Dim_Store
ON Dim_Store.StoreNumber = CASE 
                                WHEN TargetDataChannel.TargetName = 'Store Number 5' then 5
                                WHEN TargetDataChannel.TargetName = 'Store Number 8' then 8
                                WHEN TargetDataChannel.TargetName = 'Store Number 10' then 10
                                WHEN TargetDataChannel.TargetName = 'Store Number 21' then 21
                                WHEN TargetDataChannel.TargetName = 'Store Number 34' then 34
                                WHEN TargetDataChannel.TargetName = 'Store Number 39' then 39 
                                END
INNER JOIN Dim_Channel
ON Dim_Channel.ChannelName = CASE WHEN TargetDataChannel.ChannelName = 'Online' THEN 'On-line' ELSE TargetDataChannel.ChannelName END
LEFT JOIN Dim_Reseller
ON Dim_Reseller.ResellerName = TargetDataChannel.TargetName
INNER JOIN Dim_Date
ON Dim_Date.Year = TargetDataChannel.Year;


-- Fact Sales Actual
CREATE OR REPLACE TABLE Fact_SalesActual (
    DimProductID INTEGER CONSTRAINT FK_DimProductID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Product(DimProductID) NOT NULL,
    DimStoreID INTEGER CONSTRAINT FK_DimStoreID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Store(DimStoreID) NOT NULL,
    DimResellerID INTEGER CONSTRAINT FK_DimResellerID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Reseller(DimResellerID) NOT NULL,
    DimCustomerID INTEGER CONSTRAINT FK_DimCustomerID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Customer(DimCustomerID) NOT NULL,
    DimChannelID INTEGER CONSTRAINT FK_DimChannelID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Channel(DimChannelID) NOT NULL,
    DimSaleDateID NUMBER(9) CONSTRAINT FK_DimTargetDateID_Fact_SalesActual FOREIGN KEY REFERENCES Dim_Date(DATE_PKEY) NOT NULL,
    DimLocationID INTEGER CONSTRAINT FK_DimLocationID_SalesActual FOREIGN KEY REFERENCES Dim_Location(DimLocationID) NOT NULL,
    SourceSalesHeaderID INTEGER NOT NULL,
    SourceSalesDetailID INTEGER NOT NULL,
    SaleAmount FLOAT NOT NULL,
    SaleQuantity INTEGER NOT NULL,
    SaleUnitPrice FLOAT NOT NULL,
    SaleExtendedCost FLOAT NOT NULL,
    SaleTotalProfit FLOAT NOT NULL
);

INSERT INTO Fact_SalesActual (
    DimProductID,
    DimStoreID,
    DimResellerID,
    DimCustomerID,
    DimChannelID,
    DimSaleDateID,
    DimLocationID,
    SourceSalesHeaderID,
    SourceSalesDetailID,
    SaleAmount,
    SaleQuantity,
    SaleUnitPrice,
    SaleExtendedCost,
    SaleTotalProfit
)
SELECT DISTINCT 
    Dim_Product.DimProductID,
    NVL(Dim_Store.DimStoreID, -1) as DimStoreID,
	NVL(Dim_Reseller.DimResellerid, -1) as DimResellerID,
    NVL(Dim_Customer.DimCustomerID, -1) as DimCustomerID,
    Dim_Channel.DimChannelID,
    Dim_Date.Date_PKEY,
    Dim_Location.DimLocationID,
    SalesHeader.SalesHeaderID,
    SalesDetail.SalesDetailID,
    SalesDetail.SalesAmount,
    SalesDetail.SalesQuantity,
    Dim_Product.ProductRetailPrice as SaleUnitPrice,
    Dim_Product.ProductCost as SaleExtendedCost, 
    ((SaleUnitPrice - SaleExtendedCost)*SalesDetail.SalesQuantity) as SaleTotalProfit    
from SalesHeader
INNER JOIN Dim_Date  
ON SalesHeader.Date = CONCAT(Dim_Date.MONTH_NUM_IN_YEAR, '/', Dim_Date.Day_Num_In_Month, '/', SUBSTRING(Dim_Date.Year, 3, 2))
INNER JOIN SalesDetail 
ON SalesDetail.SalesHeaderID = SalesHeader.SalesHeaderID
INNER JOIN Dim_Product
ON SalesDetail.ProductID = Dim_Product.DimProductID
INNER JOIN Dim_Channel 
ON SalesHeader.ChannelID = Dim_Channel.DimChannelID
LEFT JOIN Dim_Customer
ON SalesHeader.CustomerID = Dim_Customer.CustomerID
LEFT JOIN Dim_Store
ON SalesHeader.StoreID = Dim_Store.DimStoreID
LEFT JOIN Dim_Reseller
ON SalesHeader.ResellerID = Dim_Reseller.ResellerID
INNER JOIN Dim_Location
On Dim_Location.DimLocationID = Dim_Customer.DimLocationID OR
            Dim_Location.DimLocationID = Dim_Store.DimLocationID OR
            Dim_Location.DimLocationID = Dim_Reseller.DimLocationID;

