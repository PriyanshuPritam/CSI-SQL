CREATE PROCEDURE sp_ProcessSubjectChange
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentID VARCHAR(20);
    DECLARE @RequestedSubjectID VARCHAR(20);
    DECLARE @CurrentSubjectID VARCHAR(20);

    DECLARE req_cursor CURSOR FOR
        SELECT StudentID, SubjectID FROM SubjectRequest;

    OPEN req_cursor;

    FETCH NEXT FROM req_cursor INTO @StudentID, @RequestedSubjectID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- check current valid subject for student
        SELECT TOP 1 @CurrentSubjectID = SubjectID
        FROM SubjectAllotments
        WHERE StudentID = @StudentID AND Is_Valid = 1;

        IF @CurrentSubjectID IS NOT NULL
        BEGIN
            IF @CurrentSubjectID <> @RequestedSubjectID
            BEGIN
                -- mark current subject invalid
                UPDATE SubjectAllotments
                SET Is_Valid = 0
                WHERE StudentID = @StudentID AND Is_Valid = 1;

                -- insert new subject as valid
                INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
                VALUES (@StudentID, @RequestedSubjectID, 1);
            END
            -- else: requested subject is same as current, do nothing
        END
        ELSE
        BEGIN
            -- student is not in SubjectAllotments yet
            INSERT INTO SubjectAllotments (StudentID, SubjectID, Is_Valid)
            VALUES (@StudentID, @RequestedSubjectID, 1);
        END

        FETCH NEXT FROM req_cursor INTO @StudentID, @RequestedSubjectID;
    END

    CLOSE req_cursor;
    DEALLOCATE req_cursor;
END
