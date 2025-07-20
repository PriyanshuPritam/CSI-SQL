CREATE PROCEDURE Load_SCD_Type6
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    -- Close old record if city changed
    MERGE DimCustomer_Type6 AS Target
    USING Staging_Customer AS Source
    ON Target.CustomerID = Source.CustomerID AND Target.IsCurrent = 1
    WHEN MATCHED AND Target.CurrentCity <> Source.City THEN
        UPDATE SET 
            IsCurrent = 0,
            EndDate = @Now;

    -- Insert new current record
    INSERT INTO DimCustomer_Type6 (CustomerID, Name, CurrentCity, PreviousCity, StartDate, EndDate, IsCurrent)
    SELECT
        s.CustomerID,
        s.Name,
        s.City,
        d.CurrentCity,
        @Now,
        NULL,
        1
    FROM Staging_Customer s
    LEFT JOIN DimCustomer_Type6 d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 1
    WHERE d.CustomerID IS NULL OR d.CurrentCity <> s.City;
END;
GO
