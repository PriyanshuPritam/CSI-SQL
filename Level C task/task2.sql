SELECT Name
FROM (
    SELECT s.Name, p2.Salary AS friend_salary
    FROM Students s
    JOIN Friends f ON s.ID = f.ID
    JOIN Packages p1 ON s.ID = p1.ID
    JOIN Packages p2 ON f.Friend_ID = p2.ID
    WHERE p2.Salary > p1.Salary
) AS sub
ORDER BY friend_salary DESC;