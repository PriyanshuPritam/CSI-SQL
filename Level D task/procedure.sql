IF OBJECT_ID('dbo.PopulateDimDate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PopulateDimDate;
GO

CREATE PROCEDURE dbo.PopulateDimDate
    @InputDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DateSeries AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateSeries
        WHERE DateValue < @EndDate
    )
    INSERT INTO DimDate (
        DateValue,
        DayNumberOfWeek,
        DayNameOfWeek,
        DayNumberOfMonth,
        DayNumberOfYear,
        WeekNumberOfYear,
        MonthNumberOfYear,
        MonthName,
        QuarterNumber,
        YearNumber,
        IsWeekend
    )
    SELECT 
        DateValue,
        DATEPART(WEEKDAY, DateValue),
        DATENAME(WEEKDAY, DateValue),
        DAY(DateValue),
        DATEPART(DAYOFYEAR, DateValue),
        DATEPART(WEEK, DateValue),
        MONTH(DateValue),
        DATENAME(MONTH, DateValue),
        DATEPART(QUARTER, DateValue),
        YEAR(DateValue),
        CASE WHEN DATENAME(WEEKDAY, DateValue) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
    FROM DateSeries
    OPTION (MAXRECURSION 366);
END;
GO
EXEC PopulateDimDate '2020-07-14';