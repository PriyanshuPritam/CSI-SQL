SELECT EmpID, Salary
FROM (
    SELECT EmpID, Salary, DENSE_RANK() OVER (ORDER BY Salary DESC) AS rnk
    FROM Employees
) AS ranked
WHERE rnk <= 5;