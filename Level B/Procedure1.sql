CREATE OR ALTER PROCEDURE InsertOrderDetails
    @SalesOrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @OrderQty SMALLINT,
    @Discount FLOAT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate ProductID
    IF NOT EXISTS (SELECT 1 FROM Production.Product WHERE ProductID = @ProductID)
    BEGIN
        PRINT 'Invalid ProductID.';
        RETURN;
    END

    DECLARE @StockQty INT, 
            @ReorderPoint INT, 
            @ProductUnitPrice MONEY, 
            @NewStockQty INT;

    -- Get current stock, reorder point, and product price
    SELECT 
        @StockQty = SafetyStockLevel,
        @ReorderPoint = ReorderPoint,
        @ProductUnitPrice = StandardCost
    FROM Production.Product
    WHERE ProductID = @ProductID;

    -- Check for sufficient stock
    IF @OrderQty > @StockQty
    BEGIN
        PRINT 'Not enough stock. Order aborted.';
        RETURN;
    END

    -- Set default UnitPrice if not provided
    IF @UnitPrice IS NULL
        SET @UnitPrice = @ProductUnitPrice;

    -- Insert into SalesOrderDetail
    INSERT INTO Sales.SalesOrderDetail
    (SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount)
    VALUES
    (@SalesOrderID, @ProductID, @OrderQty, @UnitPrice, @Discount);

    -- Check insertion success
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    -- Update Product stock
    UPDATE Production.Product
    SET SafetyStockLevel = SafetyStockLevel - @OrderQty
    WHERE ProductID = @ProductID;

    -- Check if stock fell below reorder point
    SELECT @NewStockQty = SafetyStockLevel
    FROM Production.Product
    WHERE ProductID = @ProductID;

    IF @NewStockQty < @ReorderPoint
    BEGIN
        PRINT 'Warning: Stock for ProductID ' + CAST(@ProductID AS VARCHAR(10)) + ' has fallen below its Reorder Level!';
    END
END;
