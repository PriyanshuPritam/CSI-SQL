INSERT INTO TargetTable (col1, col2, col3)
SELECT col1, col2, col3
FROM SourceTable
EXCEPT
SELECT col1, col2, col3
FROM TargetTable;