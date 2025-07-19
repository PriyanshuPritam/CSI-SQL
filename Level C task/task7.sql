-- Generate numbers from 2 to 1000
WITH Numbers AS (
    SELECT 2 AS num
    UNION ALL
    SELECT num + 1 FROM Numbers WHERE num + 1 <= 1000
),
Primes AS (
    SELECT num
    FROM Numbers n
    WHERE NOT EXISTS (
        SELECT 1
        FROM Numbers d
        WHERE d.num < n.num AND d.num > 1 AND n.num % d.num = 0
    )
)
SELECT STUFF((
    SELECT '&' + CAST(num AS VARCHAR)
    FROM Primes
    ORDER BY num
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, ''
) AS PrimeList
OPTION (MAXRECURSION 1000);