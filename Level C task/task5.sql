SELECT 
    s.submission_date,
    COUNT(DISTINCT s.hacker_id) AS total_hackers,
    max_hacker.hacker_id,
    h.name
FROM Submissions s
JOIN (
    SELECT 
        submission_date,
        hacker_id
    FROM (
        SELECT 
            submission_date,
            hacker_id,
            COUNT(*) AS submission_count,
            RANK() OVER (PARTITION BY submission_date ORDER BY COUNT(*) DESC, hacker_id ASC) as rnk
        FROM Submissions
        GROUP BY submission_date, hacker_id
    ) ranked
    WHERE rnk = 1
) max_hacker ON s.submission_date = max_hacker.submission_date
              AND s.hacker_id = max_hacker.hacker_id
JOIN Hackers h ON max_hacker.hacker_id = h.hacker_id
GROUP BY s.submission_date, max_hacker.hacker_id, h.name
ORDER BY s.submission_date;