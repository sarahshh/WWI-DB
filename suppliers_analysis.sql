-- ----------------------------
-- SUPPLIERS ANALYSIS
-- ----------------------------

-- Modification of the Suppliers table: add a SupplierEmail column

ALTER TABLE Purchasing.Suppliers 
ADD SupplierEmail VARCHAR(100) NULL

-- Creation of a view called StockItemsWithSuppliers that display stock and supplier information

CREATE VIEW StockItemsWithSuppliers AS
SELECT si.StockItemName, s.SupplierName, si.UnitPrice
FROM Warehouse.StockItems si
JOIN Purchasing.Suppliers s ON si.SupplierID = s.SupplierID

-- Add a constraint to PurchaseOrderLines to have OrderedOuters > 0

ALTER TABLE Purchasing.PurchaseOrderLines 
ADD CONSTRAINT CK_OrderedOuters CHECK (OrderedOuters >= 0)

-- Creation of a stored procedure called UpdateStockItemPrice to update an item price

CREATE PROCEDURE UpdateStockItemPrice
    @StockItemID INT,
    @NewPrice DECIMAL(18, 2)
AS
BEGIN
    UPDATE Warehouse.StockItems
    SET UnitPrice = @NewPrice
    WHERE StockItemID = @StockItemID
END

-- Creation of a trigger to add a record to StockItemTransactions when QuantityOnHand column is updated

CREATE TRIGGER UpdateStockItemTransaction
ON Warehouse.StockItemHoldings
AFTER UPDATE
AS
BEGIN
INSERT INTO Warehouse.StockItemTransactions (StockItemID, TransactionTypeID, Quantity, LastEditedBy, LastEditedWhen)
SELECT i.StockItemID, 1, i.QuantityOnHand - d.QuantityOnHand, d.LastEditedBy, d.LastEditedWhen
FROM deleted d
JOIN Warehouse.StockItemHoldings i ON d.StockItemID = i.StockItemID
WHERE i.QuantityOnHand <> d.QuantityOnHand
END

-- Query total quantity on hand of stock items with unit price > $10, then with unit price < $10

SELECT
    CASE
        WHEN si.UnitPrice > 10 THEN 'Greater than $10'
        ELSE 'Less than or equal to $10'
    END AS UnitPriceGroup,
    SUM(sh.QuantityOnHand) AS TotalQuantityOnHand
FROM
    Warehouse.StockItems si
    JOIN Warehouse.StockItemHoldings sh ON si.StockItemID = sh.StockItemID
WHERE
    sh.QuantityOnHand > 0
GROUP BY
    CASE
        WHEN si.UnitPrice > 10 THEN 'Greater than $10'
        ELSE 'Less than or equal to $10'
    END

-- Query the top 10 suppliers with highest order amount

WITH SupplierOrderTotals AS (
    SELECT
        s.SupplierID,
        s.SupplierName,
        COUNT(DISTINCT po.PurchaseOrderID) AS OrderCount,
        SUM(pol.ExpectedUnitPricePerOuter * pol.OrderedOuters) AS OrderTotal
    FROM
        Purchasing.Suppliers s
        JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID
        JOIN Purchasing.PurchaseOrderLines pol ON po.PurchaseOrderID = pol.PurchaseOrderID
    WHERE
        po.OrderDate >= DATEADD(YEAR, -20, GETDATE())
    GROUP BY
        s.SupplierID,
        s.SupplierName
),
RankSupplierOrderTotals AS (
    SELECT
        SupplierName,
        OrderCount,
        OrderTotal,
        DENSE_RANK() OVER (PARTITION BY NULL ORDER BY OrderTotal DESC) AS TotalRank,
        DENSE_RANK() OVER (PARTITION BY NULL ORDER BY OrderCount DESC) AS CountRank
    FROM
        SupplierOrderTotals
)

SELECT *
FROM RankSupplierOrderTotals
WHERE TotalRank <= 10
ORDER BY TotalRank ASC