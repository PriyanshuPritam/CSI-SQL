CREATE PROCEDURE Load_SCD_Type1
AS
BEGIN
    MERGE DimCustomer_Type1 AS Target
    USING Staging_Customer AS Source
    ON Target.CustomerID = Source.CustomerID
    WHEN MATCHED THEN
        UPDATE SET 
            Target.Name = Source.Name,
            Target.City = Source.City,
            Target.Email = Source.Email
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, Name, City, Email)
        VALUES (Source.CustomerID, Source.Name, Source.City, Source.Email);
END;
GO
