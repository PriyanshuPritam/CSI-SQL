CREATE OR ALTER TRIGGER trg_InsteadOfDelete_SalesOrderHeader
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    -- First, delete details for the order(s) being deleted
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM DELETED);

    -- Then, delete from SalesOrderHeader
    DELETE FROM Sales.SalesOrderHeader
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM DELETED);

    PRINT 'Order and related details successfully deleted.';
END;
