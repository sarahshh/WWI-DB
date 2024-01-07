-- ----------------------------
-- SALES ANALYSIS
-- ----------------------------

-- Creation of SalesAnalysis table

CREATE TABLE SalesAnalysis (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Country VARCHAR(50),
    Region VARCHAR(50),
    City VARCHAR(50),
    SalesAmount DECIMAL(18,2) CHECK (SalesAmount >= -1000),
    OrderDate DATE CHECK (OrderDate >= '2000-01-01' AND OrderDate <= '2099-12-31')
);

-- Populate the new table

INSERT INTO SalesAnalysis (Country, Region, City, SalesAmount, OrderDate)
SELECT 
    co.CountryName AS Country, 
    sp.StateProvinceName AS Region, 
    ci.CityName AS City, 
    SUM(il.LineProfit) AS SalesAmount, 
    o.OrderDate
FROM 
    Sales.Invoices i 
    JOIN Sales.Customers c ON i.CustomerID = c.CustomerID 
    JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID 
    JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID 
    JOIN Application.Countries co ON sp.CountryID = co.CountryID 
    JOIN Sales.Orders o ON i.OrderID = o.OrderID 
    JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID 
GROUP BY 
    co.CountryName, sp.StateProvinceName, ci.CityName, o.OrderDate;

-- Query total sales per customer category

WITH SalesSummary AS (
  SELECT 
    cc.CustomerCategoryID,
    cc.CustomerCategoryName,
    COUNT(DISTINCT o.OrderID) AS NumberOfOrders,
    SUM(ol.Quantity * ol.UnitPrice) AS TotalSalesAmount
  FROM Sales.CustomerCategories cc
  JOIN Sales.Customers c ON cc.CustomerCategoryID = c.CustomerCategoryID
  JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
  JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
  GROUP BY cc.CustomerCategoryID, cc.CustomerCategoryName
)
SELECT 
  CustomerCategoryID,
  CustomerCategoryName,
  NumberOfOrders,
  TotalSalesAmount,
  TotalSalesAmount / CAST(NumberOfOrders AS DECIMAL(18, 2)) AS AverageOrderValue
FROM SalesSummary
ORDER BY TotalSalesAmount DESC;

-- Query top 10 products with highest sales amount

SELECT TOP 10
  si.StockItemID,
  si.StockItemName,
  SUM(ol.Quantity * ol.UnitPrice) AS TotalSalesAmount
FROM Sales.OrderLines ol
JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
GROUP BY si.StockItemID, si.StockItemName
ORDER BY TotalSalesAmount DESC;

-- Calculate the monthly sales amount per customer category

SELECT 
  cc.CustomerCategoryID,
  cc.CustomerCategoryName,
  YEAR(o.OrderDate) AS OrderYear,
  MONTH(o.OrderDate) AS OrderMonth,
  SUM(ol.Quantity * ol.UnitPrice) AS MonthlySalesAmount
FROM Sales.CustomerCategories cc
JOIN Sales.Customers c ON cc.CustomerCategoryID = c.CustomerCategoryID
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
GROUP BY cc.CustomerCategoryID, cc.CustomerCategoryName, YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY OrderYear, OrderMonth, MonthlySalesAmount DESC;




