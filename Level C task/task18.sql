SELECT 
    BU,
    Month,
    ROUND(SUM(Cost * Weight) * 1.0 / NULLIF(SUM(Weight), 0), 2) AS WeightedAverageCost
FROM EmployeeCosts
GROUP BY BU, Month;