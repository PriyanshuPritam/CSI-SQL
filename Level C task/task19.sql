WITH Cleaned AS (
    SELECT 
        CAST(Salary AS VARCHAR) AS OriginalSalary,
        CAST(REGEXP_REPLACE(Salary, '[^0-9]', '', 'g') AS FLOAT) AS CleanSalary
    FROM Employees
)
SELECT 
    CEILING(ABS(AVG(CAST(OriginalSalary AS FLOAT)) - AVG(CleanSalary))) AS SalaryError
FROM Cleaned;