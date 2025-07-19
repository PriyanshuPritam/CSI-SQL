-- Create login
CREATE LOGIN new_user WITH PASSWORD = 'StrongPassword@123';

-- Create user in current DB
CREATE USER new_user FOR LOGIN new_user;

-- Grant db_owner role
EXEC sp_addrolemember 'db_owner', 'new_user';