
CREATE TABLE DimCustomer_Type0 (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR(100),
    City VARCHAR(100),
    Email VARCHAR(100)
);
GO

CREATE PROCEDURE Load_SCD_Type0
AS
BEGIN
    INSERT INTO DimCustomer_Type0 (CustomerID, Name, City, Email)
    SELECT s.CustomerID, s.Name, s.City, s.Email
    FROM Staging_Customer s
    LEFT JOIN DimCustomer_Type0 d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL;
END;
GO
