CREATE PROCEDURE Load_SCD_Type3
AS
BEGIN
    MERGE DimCustomer_Type3 AS Target
    USING Staging_Customer AS Source
    ON Target.CustomerID = Source.CustomerID
    WHEN MATCHED AND Target.CurrentCity <> Source.City THEN
        UPDATE SET 
            Target.PreviousCity = Target.CurrentCity,
            Target.CurrentCity = Source.City,
            Target.Name = Source.Name
    WHEN NOT MATCHED THEN
        INSERT (CustomerID, CurrentCity, PreviousCity, Name)
        VALUES (Source.CustomerID, Source.City, NULL, Source.Name);
END;
GO
