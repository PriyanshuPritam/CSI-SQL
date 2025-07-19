WITH ordered_tasks AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY Start_Date) AS rn
    FROM table_1
),
grouped_tasks AS (
    SELECT *,
           DATEADD(DAY, -rn, Start_Date) AS group_key
    FROM ordered_tasks
)
SELECT 
    MIN(Start_Date) AS project_start,
    MAX(End_Date) AS project_end
FROM grouped_tasks
GROUP BY group_key
ORDER BY DATEDIFF(DAY, MIN(Start_Date), MAX(End_Date)), MIN(Start_Date);