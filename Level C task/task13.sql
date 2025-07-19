SELECT 
    BU,
    Month,
    ROUND(CAST(Cost AS FLOAT) / NULLIF(Revenue, 0), 2) AS CostRevenueRatio
FROM BUData;