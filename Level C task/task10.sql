SELECT 
    c.company_code,
    c.founder,
    COUNT(DISTINCT lm.lead_manager_name) AS total_lead_managers,
    COUNT(DISTINCT sm.senior_manager_name) AS total_senior_managers,
    COUNT(DISTINCT m.manager_name) AS total_managers,
    COUNT(DISTINCT e.employee_name) AS total_employees
FROM Company c
LEFT JOIN Lead_Manager lm ON c.company_code = lm.company_code
LEFT JOIN Senior_Manager sm ON c.company_code = sm.company_code
LEFT JOIN Manager m ON c.company_code = m.company_code
LEFT JOIN Employee e ON c.company_code = e.company_code
GROUP BY c.company_code, c.founder
ORDER BY c.company_code;