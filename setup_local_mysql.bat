@echo off
echo ================================================================================
echo         FairDispatch AI - LOCAL MySQL Database Setup
echo ================================================================================
echo.
echo This script will help you set up the MySQL database on THIS laptop (localhost)
echo.
echo IMPORTANT: You will need your MySQL root password
echo ================================================================================
echo.

set MYSQL_BIN="C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"

echo Step 1: Testing MySQL Connection...
echo ----------------------------------------
%MYSQL_BIN% -u root -p -e "SELECT 'Connection successful!' as Status;"
if errorlevel 1 (
    echo.
    echo ERROR: Could not connect to MySQL!
    echo Please check:
    echo   1. MySQL is running (net start MySQL80)
    echo   2. You entered the correct password
    echo   3. MySQL is installed at: C:\Program Files\MySQL\MySQL Server 8.0
    echo.
    pause
    exit /b 1
)

echo.
echo ✅ MySQL connection successful!
echo.

echo Step 2: Creating Database...
echo ----------------------------------------
%MYSQL_BIN% -u root -p -e "CREATE DATABASE IF NOT EXISTS fairdispatch;"
if errorlevel 1 (
    echo ERROR: Failed to create database!
    pause
    exit /b 1
)
echo ✅ Database 'fairdispatch' created!
echo.

echo Step 3: Importing Schema and Data...
echo ----------------------------------------
echo This will import all tables, data, views, procedures, and triggers...
%MYSQL_BIN% -u root -p fairdispatch < database_setup.sql
if errorlevel 1 (
    echo ERROR: Failed to import database schema!
    pause
    exit /b 1
)
echo ✅ Schema and data imported successfully!
echo.

echo Step 4: Verifying Setup...
echo ----------------------------------------
echo Checking tables...
%MYSQL_BIN% -u root -p fairdispatch -e "SHOW TABLES;"
echo.
echo Checking user count...
%MYSQL_BIN% -u root -p fairdispatch -e "SELECT COUNT(*) as user_count FROM users;"
echo.
echo Checking route count...
%MYSQL_BIN% -u root -p fairdispatch -e "SELECT COUNT(*) as route_count FROM routes;"
echo.

echo ================================================================================
echo                          ✅ SETUP COMPLETE!
echo ================================================================================
echo.
echo Your database is now ready at: localhost:3306/fairdispatch
echo.
echo Next steps:
echo   1. Update backend configuration to use localhost
echo   2. Start the backend server
echo.
echo To update backend configuration, set these environment variables:
echo   set MYSQL_HOST=localhost
echo   set MYSQL_PASSWORD=your_mysql_password
echo.
echo Or edit: backend\app\database.py
echo   Change MYSQL_HOST from "192.168.112.235" to "localhost"
echo.
echo ================================================================================
pause
