CREATE OR ALTER VIEW MyProducts AS
SELECT 
    P.ProductID,
    P.Name AS ProductName,
    P.Size AS QuantityPerUnit,         -- Size used as "Quantity Per Unit"
    P.ListPrice AS UnitPrice,          -- Using ListPrice for UnitPrice
    V.Name AS VendorName,              -- Supplier Name
    PC.Name AS CategoryName            -- Category Name
FROM 
    Production.Product AS P
    INNER JOIN Purchasing.ProductVendor AS PV ON P.ProductID = PV.ProductID
    INNER JOIN Purchasing.Vendor AS V ON PV.BusinessEntityID = V.BusinessEntityID
    INNER JOIN Production.ProductSubcategory AS PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
    INNER JOIN Production.ProductCategory AS PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE 
    P.DiscontinuedDate IS NULL;        -- Only active (not discontinued) products
