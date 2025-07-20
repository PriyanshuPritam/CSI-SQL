CREATE PROCEDURE Load_SCD_Type4
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    -- Insert into History Table for Changed Records
    INSERT INTO DimCustomer_Type4_History (CustomerID, Name, City, Email, ChangeDate)
    SELECT d.CustomerID, d.Name, d.City, d.Email, @Now
    FROM DimCustomer_Type4 d
    INNER JOIN Staging_Customer s ON s.CustomerID = d.CustomerID
    WHERE d.Name <> s.Name OR d.City <> s.City OR d.Email <> s.Email;

    -- Overwrite Dimension Table with New Data
    MERGE DimCustomer_Type4 AS Target
    USING Staging_Customer AS Source
    ON Target.CustomerID = Source.CustomerID
    WHEN MATCHED THEN
        UPDATE SET 
            Name = Source.Name,
            City = Source.City,
            Email = Source.Email
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, Name, City, Email)
        VALUES (Source.CustomerID, Source.Name, Source.City, Source.Email);
END;
GO
