@echo off
echo ========================================
echo MySQL Connection Diagnostics
echo ========================================
echo.

echo Testing connection to MySQL server...
echo Host: 192.168.112.235
echo Port: 3306
echo.

echo Step 1: Ping Test
echo ----------------------------------------
ping -n 2 192.168.112.235

if errorlevel 1 (
    echo.
    echo [FAILED] Cannot ping MySQL server
    echo.
    echo Possible issues:
    echo 1. MySQL laptop is not on the same network
    echo 2. MySQL laptop is turned off
    echo 3. IP address has changed
    echo 4. Firewall is blocking ping
    echo.
    goto :troubleshoot
) else (
    echo [SUCCESS] MySQL server is reachable
    echo.
)

echo Step 2: Port Test
echo ----------------------------------------
echo Checking if port 3306 is open...
powershell -Command "Test-NetConnection -ComputerName 192.168.112.235 -Port 3306"

echo.
echo Step 3: MySQL Client Test
echo ----------------------------------------
echo Trying to connect with MySQL client...
echo (If you have MySQL client installed)
echo.
mysql -h 192.168.112.235 -u root -proot123 -e "SELECT 1"

if errorlevel 1 (
    echo.
    echo [FAILED] Cannot connect to MySQL
    goto :troubleshoot
) else (
    echo [SUCCESS] MySQL connection works!
    echo.
)

goto :end

:troubleshoot
echo.
echo ========================================
echo Troubleshooting Steps
echo ========================================
echo.
echo ON THE MYSQL LAPTOP (192.168.112.235):
echo.
echo 1. Check MySQL is running:
echo    netstat -an ^| findstr 3306
echo    (Should show: 0.0.0.0:3306 or *:3306)
echo.
echo 2. Check firewall allows port 3306:
echo    netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
echo.
echo 3. Verify MySQL config allows remote connections:
echo    - Edit my.ini file
echo    - Find: bind-address = 127.0.0.1
echo    - Change to: bind-address = 0.0.0.0
echo    - Restart MySQL
echo.
echo 4. Grant remote access:
echo    mysql -u root -p
echo    GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%%' IDENTIFIED BY 'root123';
echo    FLUSH PRIVILEGES;
echo.
echo 5. Verify IP address hasn't changed:
echo    ipconfig
echo    (Check IPv4 Address)
echo.
echo ON YOUR LAPTOP:
echo.
echo 1. Ensure both laptops are on same WiFi network
echo.
echo 2. Check Windows Firewall isn't blocking outgoing connections
echo.
echo 3. Try using SQLite instead (already configured as fallback)
echo.
echo ========================================
echo.

:end
echo.
echo ========================================
echo Current Status
echo ========================================
echo.
echo Backend is using: SQLite (fallback)
echo This is FINE for your demo!
echo.
echo To use MySQL, fix the issues above.
echo To continue with SQLite, no action needed.
echo.
echo ========================================
pause
