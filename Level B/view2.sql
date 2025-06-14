CREATE OR ALTER VIEW vwCustomerOrders_Yesterday AS
SELECT 
    S.Name AS CompanyName,
    SH.SalesOrderID,
    SH.OrderDate,
    SD.ProductID,
    P.Name AS ProductName,
    SD.OrderQty AS Quantity,
    SD.UnitPrice,
    (SD.OrderQty * SD.UnitPrice) AS TotalPrice
FROM 
    Sales.Customer C
    INNER JOIN Sales.Store S ON C.StoreID = S.BusinessEntityID
    INNER JOIN Sales.SalesOrderHeader SH ON C.CustomerID = SH.CustomerID
    INNER JOIN Sales.SalesOrderDetail SD ON SH.SalesOrderID = SD.SalesOrderID
    INNER JOIN Production.Product P ON SD.ProductID = P.ProductID
WHERE 
    CAST(SH.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
