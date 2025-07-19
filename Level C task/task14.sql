SELECT 
    SubBand,
    COUNT(*) AS HeadCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS HeadCountPercentage
FROM Employees
GROUP BY SubBand;