CREATE OR ALTER PROCEDURE DeleteOrderDetails
    @SalesOrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate parameters
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Invalid parameters: No such OrderID and ProductID combination found.';
        RETURN -1;
    END

    -- Restore stock before deletion
    DECLARE @Qty INT;

    SELECT @Qty = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID;

    UPDATE Production.Product
    SET SafetyStockLevel = SafetyStockLevel + @Qty
    WHERE ProductID = @ProductID;

    -- Delete the order
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID;

    PRINT 'Order detail deleted successfully.';
END;
