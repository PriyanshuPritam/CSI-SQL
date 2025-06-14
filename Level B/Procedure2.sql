CREATE OR ALTER PROCEDURE UpdateOrderDetails
    @SalesOrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @OrderQty SMALLINT = NULL,
    @Discount FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate if record exists
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'OrderID and ProductID combination does not exist.';
        RETURN;
    END

    DECLARE @OldQty INT;

    -- Get existing quantity
    SELECT @OldQty = OrderQty
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID;

    -- Adjust stock: revert old qty, apply new qty if given
    IF @OrderQty IS NOT NULL
    BEGIN
        UPDATE Production.Product
        SET SafetyStockLevel = SafetyStockLevel + @OldQty - @OrderQty
        WHERE ProductID = @ProductID;
    END

    -- Perform the update
    UPDATE Sales.SalesOrderDetail
    SET 
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@OrderQty, OrderQty),
        UnitPriceDiscount = ISNULL(@Discount, UnitPriceDiscount)
    WHERE SalesOrderID = @SalesOrderID AND ProductID = @ProductID;

    PRINT 'Order details updated successfully.';
END;
