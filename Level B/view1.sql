CREATE OR ALTER VIEW vwCustomerOrders AS
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
    Sales.Customer AS C
    INNER JOIN Sales.Store AS S ON C.StoreID = S.BusinessEntityID
    INNER JOIN Sales.SalesOrderHeader AS SH ON C.CustomerID = SH.CustomerID
    INNER JOIN Sales.SalesOrderDetail AS SD ON SH.SalesOrderID = SD.SalesOrderID
    INNER JOIN Production.Product AS P ON SD.ProductID = P.ProductID;
