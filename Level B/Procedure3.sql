CREATE OR ALTER PROCEDURE GetOrderDetails
    @SalesOrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @SalesOrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@SalesOrderID AS VARCHAR(10)) + ' does not exist.';
        RETURN 1;
    END

    SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = @SalesOrderID;
END;
