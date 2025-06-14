CREATE OR ALTER TRIGGER trg_CheckStockBeforeInsert
ON Sales.SalesOrderDetail
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @ProductID INT,
            @OrderQty INT,
            @AvailableQty INT,
            @SalesOrderID INT,
            @UnitPrice MONEY,
            @UnitPriceDiscount MONEY;

    -- Get values from the inserted row (assumes single-row insert)
    SELECT 
        @ProductID = ProductID,
        @OrderQty = OrderQty,
        @SalesOrderID = SalesOrderID,
        @UnitPrice = UnitPrice,
        @UnitPriceDiscount = UnitPriceDiscount
    FROM INSERTED;

    -- Get available quantity from Production.ProductInventory (LocationID 1)
    SELECT @AvailableQty = Quantity
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID AND LocationID = 1;

    -- Check if enough stock
    IF @AvailableQty IS NULL OR @AvailableQty < @OrderQty
    BEGIN
        PRINT 'Error: Not enough stock to fulfill the order. Insert canceled.';
        RETURN; -- Cancel the insert
    END
    ELSE
    BEGIN
        -- Adjust stock in inventory
        UPDATE Production.ProductInventory
        SET Quantity = Quantity - @OrderQty
        WHERE ProductID = @ProductID AND LocationID = 1;

        -- Perform the actual insert into SalesOrderDetail
        INSERT INTO Sales.SalesOrderDetail
        (
            SalesOrderID,
            CarrierTrackingNumber,
            OrderQty,
            ProductID,
            SpecialOfferID,
            UnitPrice,
            UnitPriceDiscount,
            rowguid,
            ModifiedDate
        )
        SELECT
            @SalesOrderID,
            NULL, -- CarrierTrackingNumber is nullable
            @OrderQty,
            @ProductID,
            1, -- SpecialOfferID (assuming 1 is the default valid value)
            @UnitPrice,
            @UnitPriceDiscount,
            NEWID(),
            GETDATE();
        
        PRINT 'Order placed and stock adjusted successfully.';
    END
END;
