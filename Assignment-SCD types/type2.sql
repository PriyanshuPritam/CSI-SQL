CREATE PROCEDURE Load_SCD_Type2
AS
BEGIN
    DECLARE @CurrentDate DATETIME = GETDATE();

    -- Close Current Records if Data Changes
    MERGE DimCustomer_Type2 AS Target
    USING Staging_Customer AS Source
    ON Target.CustomerID = Source.CustomerID AND Target.IsCurrent = 1
    WHEN MATCHED AND (
        Target.Name <> Source.Name OR
        Target.City <> Source.City OR
        Target.Email <> Source.Email
    )
    THEN
        UPDATE SET
            Target.EndDate = @CurrentDate,
            Target.IsCurrent = 0;

    -- Insert New Current Record
    INSERT INTO DimCustomer_Type2 (CustomerID, Name, City, Email, StartDate, EndDate, IsCurrent)
    SELECT s.CustomerID, s.Name, s.City, s.Email, @CurrentDate, NULL, 1
    FROM Staging_Customer s
    LEFT JOIN DimCustomer_Type2 d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 1
    WHERE d.CustomerID IS NULL OR
          d.Name <> s.Name OR d.City <> s.City OR d.Email <> s.Email;
END;
GO
