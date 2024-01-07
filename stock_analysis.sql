-- ----------------------------
-- STOCK ANALYSIS
-- ----------------------------

-- Creation of a new table called StockItemAvailability to check item availability on a specific date, and relevant constraints

CREATE TABLE Warehouse.StockItemAvailability (
    StockItemID INT NOT NULL,
    Date DATE NOT NULL,
    AvailableQuantity INT NOT NULL,
    CONSTRAINT FK_StockItemAvailability_StockItems FOREIGN KEY (StockItemID) REFERENCES Warehouse.StockItems (StockItemID)
);

ALTER TABLE Warehouse.StockItemAvailability
ADD CONSTRAINT CHK_StockItemAvailability_AvailableQuantity CHECK (AvailableQuantity >= 0);

ALTER TABLE Warehouse.StockItemHoldings
ADD Notes VARCHAR(255) NULL;

-- Creation of a view called LowStockItems to show all stock items where QuantityOnHand is less than ReorderLevel

CREATE VIEW Warehouse.LowStockItems AS
SELECT StockItems.StockItemName, StockItemHoldings.QuantityOnHand, StockItemHoldings.ReorderLevel
FROM Warehouse.StockItems
INNER JOIN Warehouse.StockItemHoldings ON StockItems.StockItemID = StockItemHoldings.StockItemID
WHERE QuantityOnHand < ReorderLevel;

-- Creation of a stored procedure called AddStockItemTransaction to add stock item to StockItemTransactions table

CREATE PROCEDURE Warehouse.AddStockItemTransaction (
    @StockItemID INT,
    @TransactionTypeID INT,
    @CustomerID INT,
    @InvoiceID INT,
    @SupplierID INT,
    @PurchaseOrderID INT,
    @Quantity INT,
    @LastEditedBy INT
)
AS
BEGIN
    INSERT INTO Warehouse.StockItemTransactions (
        StockItemID,
        TransactionTypeID,
        CustomerID,
        InvoiceID,
        SupplierID,
        PurchaseOrderID,
        TransactionOccurredWhen,
        Quantity,
        LastEditedBy
    )
    VALUES (
        @StockItemID,
        @TransactionTypeID,
        @CustomerID,
        @InvoiceID,
        @SupplierID,
        @PurchaseOrderID,
        GETDATE(),
        @Quantity,
        @LastEditedBy
    );
END;

-- Creation of a trigger to update LastEditedWhen automatically when a new transaction is added to the table

CREATE TRIGGER Warehouse.UpdateStockItemHoldingsLastEditedWhen
ON Warehouse.StockItemTransactions
AFTER INSERT
AS
BEGIN
    UPDATE Warehouse.StockItemHoldings
    SET LastEditedWhen = GETDATE()
    WHERE StockItemID IN (
        SELECT StockItemID
        FROM inserted
    );
END;

-- Query info on stock items that have a RecommendedRetailPrice > 50

SELECT StockItems.StockItemName, StockItemHoldings.QuantityOnHand, StockItems.RecommendedRetailPrice
FROM Warehouse.StockItems
INNER JOIN Warehouse.StockItemHoldings ON StockItems.StockItemID = StockItemHoldings.StockItemID
WHERE StockItems.RecommendedRetailPrice > 50 AND StockItemHoldings.QuantityOnHand > 0;

-- Query info on stock items that belong to 'Clothing'

SELECT StockGroups.StockGroupName, StockItems.StockItemName, StockItemHoldings.QuantityOnHand
FROM Warehouse.StockItems
INNER JOIN Warehouse.StockItemHoldings ON StockItems.StockItemID = StockItemHoldings.StockItemID
INNER JOIN Warehouse.StockItemStockGroups ON StockItems.StockItemID = StockItemStockGroups.StockItemID
INNER JOIN Warehouse.StockGroups ON StockItemStockGroups.StockGroupID = StockGroups.StockGroupID
WHERE StockGroups.StockGroupName = 'Clothing';

-- Query total quantity of transactions for each StockItemID

SELECT StockItemID, SUM(Quantity) AS TotalQuantity
FROM Warehouse.StockItemTransactions
GROUP BY StockItemID;

-- Query top 5 stock items with highest QuantityOnHand

SELECT TOP 5 StockItems.StockItemName, StockItemHoldings.QuantityOnHand
FROM Warehouse.StockItems
INNER JOIN Warehouse.StockItemHoldings ON StockItems.StockItemID = StockItemHoldings.StockItemID
ORDER BY QuantityOnHand DESC;

-- Query info on stock items that have RecommendedRetailPrice > avg RecommendedRetailPrice for all items

SELECT StockItems.StockItemName, StockItemHoldings.QuantityOnHand, StockItems.RecommendedRetailPrice
FROM Warehouse.StockItems
INNER JOIN Warehouse.StockItemHoldings ON StockItems.StockItemID = StockItemHoldings.StockItemID
WHERE StockItems.RecommendedRetailPrice > (
    SELECT AVG(RecommendedRetailPrice)
    FROM Warehouse.StockItems
);

-- Query info on stock items that have RecommendedRetailPrice > 50 and belong to 'Clothing'

SELECT si.StockItemName, sih.QuantityOnHand, si.RecommendedRetailPrice
FROM Warehouse.StockItems si
INNER JOIN Warehouse.StockItemHoldings sih ON si.StockItemID = sih.StockItemID
INNER JOIN Warehouse.StockItemStockGroups sig ON si.StockItemID = sig.StockItemID
INNER JOIN Warehouse.StockGroups sg ON sig.StockGroupID = sg.StockGroupID
WHERE sg.StockGroupName = 'Clothing' AND si.RecommendedRetailPrice > 50;