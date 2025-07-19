CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    SET NOCOUNT ON;

    -- cleanup previous data
    TRUNCATE TABLE Allotments;
    TRUNCATE TABLE UnallottedStudents;

    DECLARE @StudentId BIGINT;

    -- declare student cursor
    DECLARE student_cursor CURSOR FOR
    SELECT StudentId
    FROM StudentDetails
    ORDER BY GPA DESC;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Preference INT = 1;
        DECLARE @SubjectId VARCHAR(20);
        DECLARE @allocated BIT = 0;

        WHILE @Preference <= 5 AND @allocated = 0
        BEGIN
            SELECT @SubjectId = SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId
              AND Preference = @Preference;

            IF @SubjectId IS NOT NULL
            BEGIN
                DECLARE @RemainingSeats INT;
                SELECT @RemainingSeats = RemainingSeats
                FROM SubjectDetails
                WHERE SubjectId = @SubjectId;

                IF @RemainingSeats > 0
                BEGIN
                    -- allocate
                    INSERT INTO Allotments(SubjectId, StudentId)
                    VALUES (@SubjectId, @StudentId);

                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectId = @SubjectId;

                    SET @allocated = 1;
                END
            END

            SET @Preference = @Preference + 1;
        END

        IF @allocated = 0
        BEGIN
            INSERT INTO UnallottedStudents(StudentId)
            VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END

