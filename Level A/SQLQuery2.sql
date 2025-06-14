
-- 1. List of all customers
SELECT * FROM Sales.Customer;

-- 2. Customers where company name ends in 'N'
SELECT * FROM Sales.Customer WHERE CustomerID IN (
    SELECT CustomerID FROM Sales.Store WHERE Name LIKE '%N'
);

-- 3. Customers who live in Berlin or London
SELECT * FROM Person.Address WHERE City IN ('Berlin', 'London');

-- 4. Customers who live in UK or USA
SELECT * FROM Person.Address a
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name IN ('United Kingdom', 'United States');

-- 5. All products sorted by product name
SELECT * FROM Production.Product ORDER BY Name;

-- 6. Products where name starts with 'A'
SELECT * FROM Production.Product WHERE Name LIKE 'A%';

-- 7. Customers who ever placed an order
SELECT DISTINCT CustomerID FROM Sales.SalesOrderHeader;

-- 8. Customers in London who bought 'Chai'
SELECT DISTINCT soh.CustomerID
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.BillToAddressID = a.AddressID
WHERE a.City = 'London' AND p.Name = 'Chai';

-- 9. Customers who never placed an order
SELECT c.CustomerID
FROM Sales.Customer c
LEFT JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
WHERE soh.SalesOrderID IS NULL;

-- 10. Customers who ordered 'Tofu'
SELECT DISTINCT soh.CustomerID
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Name = 'Tofu';

-- 11. First order in the system
SELECT TOP 1 * FROM Sales.SalesOrderHeader ORDER BY OrderDate;

-- 12. Details of most expensive order (based on line total)
SELECT TOP 1 soh.SalesOrderID, SUM(sod.LineTotal) AS Total
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY soh.SalesOrderID
ORDER BY Total DESC;

-- 13. OrderID and average quantity of items in each order
SELECT SalesOrderID, AVG(OrderQty) AS AvgQty
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- 14. OrderID, min and max quantity for each order
SELECT SalesOrderID, MIN(OrderQty) AS MinQty, MAX(OrderQty) AS MaxQty
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID;

-- 15. Managers and number of employees reporting to them
SELECT e.OrganizationNode.ToString() AS ManagerPath, COUNT(*) AS ReportCount
FROM HumanResources.Employee e
WHERE e.OrganizationNode IS NOT NULL
GROUP BY e.OrganizationNode.ToString();

-- 16. Orders with total quantity > 300
SELECT SalesOrderID, SUM(OrderQty) AS TotalQty
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(OrderQty) > 300;

-- 17. Orders on or after 1996-12-31
SELECT * FROM Sales.SalesOrderHeader WHERE OrderDate >= '1996-12-31';

-- 18. Orders shipped to Canada
SELECT * FROM Sales.SalesOrderHeader
WHERE ShipToAddressID IN (
    SELECT AddressID FROM Person.Address WHERE StateProvinceID IN (
        SELECT StateProvinceID FROM Person.StateProvince WHERE CountryRegionCode = 'CA'
    )
);

-- 19. Orders with order total > 200
SELECT SalesOrderID, SUM(LineTotal) AS Total
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
HAVING SUM(LineTotal) > 200;

-- 20. Countries and sales made in each
SELECT cr.Name AS Country, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name;

-- 21. ContactName and number of orders
SELECT p.FirstName + ' ' + p.LastName AS ContactName, COUNT(soh.SalesOrderID) AS OrdersCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY p.FirstName, p.LastName;

-- 22. Customers with more than 3 orders
SELECT CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 3;

-- 23. Discontinued products ordered between dates
SELECT DISTINCT p.Name
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
WHERE p.SellEndDate IS NOT NULL
  AND soh.OrderDate BETWEEN '1997-01-01' AND '1998-01-01';

-- 24. Employees and their supervisors
SELECT e.BusinessEntityID AS EmployeeID, e.JobTitle,
       m.BusinessEntityID AS ManagerID, m.JobTitle AS ManagerTitle
FROM HumanResources.Employee e
LEFT JOIN HumanResources.Employee m ON e.OrganizationNode.GetAncestor(1) = m.OrganizationNode;

-- 25. Employee ID and total sales
SELECT soh.SalesPersonID AS EmployeeID, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
WHERE soh.SalesPersonID IS NOT NULL
GROUP BY soh.SalesPersonID;

-- 26. Employees with 'a' in first name
SELECT * FROM Person.Person WHERE FirstName LIKE '%a%';

-- 27. Managers with more than four people reporting to them
SELECT Manager.BusinessEntityID AS ManagerID, COUNT(*) AS DirectReports
FROM HumanResources.Employee Emp
JOIN HumanResources.Employee Manager ON Emp.OrganizationNode.GetAncestor(1) = Manager.OrganizationNode
GROUP BY Manager.BusinessEntityID
HAVING COUNT(*) > 4;

-- 28. Orders and product names
SELECT soh.SalesOrderID, p.Name
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID;

-- 29. Orders placed by best customer
WITH BestCustomer AS (
    SELECT TOP 1 CustomerID, COUNT(*) AS OrderCount
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    ORDER BY OrderCount DESC
)
SELECT * FROM Sales.SalesOrderHeader
WHERE CustomerID = (SELECT CustomerID FROM BestCustomer);

-- 30. Orders by customers without Fax
SELECT soh.*
FROM Sales.SalesOrderHeader soh
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
LEFT JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE p.EmailPromotion = 0; -- Assuming EmailPromotion is used as proxy, as no Fax column

-- 31. Postal codes where Tofu was shipped
SELECT DISTINCT a.PostalCode
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
WHERE p.Name = 'Tofu';

-- 32. Product names shipped to France
SELECT DISTINCT p.Name
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
WHERE sp.CountryRegionCode = 'FR';

-- 33. Products and categories from "Specialty Biscuits, Ltd."
SELECT p.Name AS ProductName, pc.Name AS CategoryName
FROM Production.Product p
JOIN Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN Production.ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
JOIN Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
WHERE v.Name = 'Specialty Biscuits, Ltd.';

-- 34. Products never ordered
SELECT * FROM Production.Product
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM Sales.SalesOrderDetail);

-- 35. Products low on stock and no units on order
SELECT * FROM Production.Product
WHERE SafetyStockLevel < 10 AND ReorderPoint = 0;

-- 36. Top 10 countries by sales
SELECT TOP 10 cr.Name AS Country, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Person.Address a ON soh.ShipToAddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY cr.Name
ORDER BY TotalSales DESC;

-- 37. Orders per employee for CustomerIDs between A and AO (simulate with range)
SELECT SalesPersonID, COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
WHERE CustomerID BETWEEN 1 AND 100
GROUP BY SalesPersonID;

-- 38. Order date of most expensive order
SELECT TOP 1 soh.OrderDate, SUM(sod.LineTotal) AS Total
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY soh.SalesOrderID, soh.OrderDate
ORDER BY Total DESC;

-- 39. Product name and total revenue
SELECT p.Name, SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name;

-- 40. SupplierID and number of products offered
SELECT pv.BusinessEntityID AS SupplierID, COUNT(*) AS ProductCount
FROM Purchasing.ProductVendor pv
GROUP BY pv.BusinessEntityID;

-- 41. Top 10 customers based on total purchase
SELECT TOP 10 soh.CustomerID, SUM(sod.LineTotal) AS TotalSpent
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY soh.CustomerID
ORDER BY TotalSpent DESC;

-- 42. Total revenue of the company
SELECT SUM(LineTotal) AS TotalRevenue FROM Sales.SalesOrderDetail;
