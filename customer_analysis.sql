-- ----------------------------
-- CUSTOMER ANALYSIS
-- ----------------------------

-- Creation of a CustomerAnalysis table

CREATE TABLE CustomerAnalysis (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    CustomerName VARCHAR(100),
    Country VARCHAR(50),
    Region VARCHAR(50),
    City VARCHAR(50),
    TotalSales DECIMAL(18,2),
    NumberOfOrders INT,
    AverageOrderValue DECIMAL(18,2)
);

-- Creation of a procedure usp_InsertCustomerAnalysis

CREATE PROCEDURE usp_InsertCustomerAnalysis
AS
BEGIN
  INSERT INTO CustomerAnalysis (
    CustomerID,
    CustomerName,
    Country,
    Region,
    City,
    TotalSales,
    NumberOfOrders,
    AverageOrderValue
  )
  SELECT
    c.CustomerID,
    c.CustomerName,
    ctr.CountryName,
    sp.StateProvinceName,
    ci.CityName,
    SUM(ol.UnitPrice * ol.Quantity) AS TotalSales,
    COUNT(DISTINCT o.OrderID) AS NumberOfOrders,
    AVG(ot.OrderTotal) AS AverageOrderValue
  FROM Sales.Customers c
  JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
  JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
  JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
  JOIN Application.Cities ci ON c.DeliveryCityID = ci.CityID
  JOIN Application.StateProvinces sp ON ci.StateProvinceID = sp.StateProvinceID
  JOIN Application.Countries ctr ON sp.CountryID = ctr.CountryID
  JOIN (
    SELECT OrderID, SUM(UnitPrice * Quantity) AS OrderTotal
    FROM Sales.OrderLines
    GROUP BY OrderID
  ) ot ON o.OrderID = ot.OrderID
  GROUP BY 
    c.CustomerID,
    c.CustomerName,
    ctr.CountryName,
    sp.StateProvinceName,
    ci.CityName
END;

-- Execution of the procedure

EXEC usp_InsertCustomerAnalysis;

-- Creation of a procedure usp_GetCustomerSegmentation

CREATE PROCEDURE usp_GetCustomerSegmentation
  @SalesThreshold DECIMAL(18,2)
AS
BEGIN
  SELECT 
    c.CustomerID,
    c.CustomerName,
    SUM(il.LineProfit) AS 'Total sales',
    CASE 
      WHEN SUM(il.LineProfit) >= @SalesThreshold THEN 'Premium'
      ELSE 'Standard'
    END AS CustomerSegment
  FROM Sales.Customers c
  JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
  JOIN Sales.Invoices i ON o.OrderID = i.OrderID
  JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
  GROUP BY c.CustomerID, c.CustomerName
END;

-- Execution of the procedure

EXEC usp_GetCustomerSegmentation 100000; -- Replace 100000 with your desired threshold

-- Query the average order value per customer category

SELECT
  cc.CustomerCategoryName,
  AVG(il.LineProfit) AS AverageOrderValue
FROM Sales.CustomerCategories cc
JOIN Sales.Customers c ON cc.CustomerCategoryID = c.CustomerCategoryID
JOIN Sales.Orders o ON c.CustomerID = o.CustomerID
JOIN Sales.Invoices i ON o.OrderID = i.OrderID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
GROUP BY cc.CustomerCategoryName;

-- Query the order count and total sales (LineProfit) for each city

SELECT c.CityName, COUNT(DISTINCT o.OrderID) AS NumberOfOrders, SUM(il.LineProfit) AS TotalSales
FROM Sales.Orders o
JOIN Sales.Invoices i ON o.OrderID = i.OrderID
JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
JOIN Sales.Customers cu ON o.CustomerID = cu.CustomerID
JOIN Application.Cities c ON cu.DeliveryCityID = c.CityID
GROUP BY c.CityName
ORDER BY TotalSales DESC;



