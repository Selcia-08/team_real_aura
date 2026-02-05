@echo off
echo ========================================
echo Remote MySQL Configuration
echo ========================================
echo.

echo Please provide the following information:
echo.

set /p MYSQL_IP="Enter MySQL laptop IP address (e.g., 192.168.1.100): "
set /p MYSQL_PASS="Enter MySQL root password: "

echo.
echo ========================================
echo Testing Connection...
echo ========================================
echo.

echo Pinging MySQL server...
ping -n 2 %MYSQL_IP%

if errorlevel 1 (
    echo.
    echo [ERROR] Cannot reach MySQL server at %MYSQL_IP%
    echo Please check:
    echo 1. Both laptops are on the same network
    echo 2. IP address is correct
    echo 3. MySQL laptop is powered on
    echo.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] MySQL server is reachable!
echo.

echo ========================================
echo Configuring Environment Variables...
echo ========================================
echo.

set MYSQL_HOST=%MYSQL_IP%
set MYSQL_PASSWORD=%MYSQL_PASS%

echo MYSQL_HOST set to: %MYSQL_HOST%
echo MYSQL_PASSWORD set to: ********
echo.

echo ========================================
echo Starting Backend with Remote MySQL...
echo ========================================
echo.

cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

pause
