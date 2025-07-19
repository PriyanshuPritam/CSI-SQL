SELECT 
    JobFamily,
    Region,
    ROUND(SUM(Cost) * 100.0 / SUM(SUM(Cost)) OVER (PARTITION BY JobFamily), 2) AS Cost_Percentage
FROM JobCosts
GROUP BY JobFamily, Region;