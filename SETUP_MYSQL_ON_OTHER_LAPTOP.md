# 🌐 Complete Guide: Running Database on Another Laptop

## Setup Overview

**MySQL Laptop (192.168.112.235):**
- Install MySQL
- Create database
- Configure for remote access
- Run database_setup.sql

**Your Laptop (Development):**
- Already configured ✅
- Connect to remote MySQL
- Run backend and app

---

## PART 1: On MySQL Laptop (192.168.112.235)

### Step 1: Install MySQL (If not already installed)

1. **Download MySQL:**
   - Visit: https://dev.mysql.com/downloads/mysql/
   - Choose: MySQL Community Server 8.0
   - Download Windows installer

2. **Install MySQL:**
   - Run installer
   - Choose "Server only" or "Developer Default"
   - Set root password: `root123` (must match your config!)
   - Complete installation

3. **Verify Installation:**
   ```cmd
   mysql --version
   ```

### Step 2: Create Database and Import Schema

1. **Open Command Prompt as Administrator**

2. **Login to MySQL:**
   ```cmd
   mysql -u root -p
   ```
   Enter password: `root123`

3. **Create Database:**
   ```sql
   CREATE DATABASE fairdispatch;
   SHOW DATABASES;
   -- You should see 'fairdispatch' in the list
   EXIT;
   ```

4. **Import Database Schema:**
   
   **Option A: If you have database_setup.sql file on MySQL laptop:**
   ```cmd
   mysql -u root -proot123 fairdispatch < database_setup.sql
   ```

   **Option B: If file is on your laptop, copy it first:**
   - Copy `database_setup.sql` to USB drive
   - Transfer to MySQL laptop
   - Then run:
   ```cmd
   mysql -u root -proot123 fairdispatch < path\to\database_setup.sql
   ```

   **Option C: Manual SQL execution:**
   ```cmd
   mysql -u root -proot123 fairdispatch
   ```
   Then copy-paste the SQL from `database_setup.sql` file

5. **Verify Tables Created:**
   ```sql
   mysql -u root -proot123 fairdispatch
   SHOW TABLES;
   ```
   
   You should see:
   ```
   +------------------------+
   | Tables_in_fairdispatch |
   +------------------------+
   | admins                 |
   | assignments            |
   | credit_logs            |
   | notifications          |
   | routes                 |
   | users                  |
   | weekly_policies        |
   +------------------------+
   ```

6. **Verify Sample Data:**
   ```sql
   SELECT COUNT(*) FROM users;
   -- Should return 5
   
   SELECT COUNT(*) FROM routes;
   -- Should return 6
   
   SELECT name, employee_id FROM users WHERE role = 'DRIVER';
   -- Should show 4 drivers
   
   EXIT;
   ```

### Step 3: Configure MySQL for Remote Access

#### 3.1 Edit MySQL Configuration File

1. **Find my.ini file:**
   - Location: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
   - Or search for "my.ini" in MySQL installation folder

2. **Open as Administrator:**
   - Right-click my.ini
   - "Open with" → Notepad
   - Run as Administrator

3. **Find and Change bind-address:**
   ```ini
   # Find this line (usually under [mysqld] section):
   bind-address = 127.0.0.1
   
   # Change to:
   bind-address = 0.0.0.0
   ```
   
   **Note:** `0.0.0.0` means MySQL will accept connections from any IP

4. **Save and Close**

#### 3.2 Grant Remote Access Permissions

```cmd
mysql -u root -proot123

-- Grant access from any IP
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'root123';

-- Alternative: Grant access from specific IP only (more secure)
-- GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'192.168.112.XXX' IDENTIFIED BY 'root123';

FLUSH PRIVILEGES;

-- Verify
SELECT user, host FROM mysql.user WHERE user='root';
-- Should show root@% or root@your-ip

EXIT;
```

#### 3.3 Restart MySQL Service

**Option A: Using Services:**
1. Press `Win + R`
2. Type: `services.msc`
3. Find "MySQL80" (or your MySQL version)
4. Right-click → Restart

**Option B: Using Command Prompt (as Administrator):**
```cmd
net stop MySQL80
net start MySQL80
```

#### 3.4 Configure Windows Firewall

**Open Command Prompt as Administrator:**
```cmd
netsh advfirewall firewall add rule name="MySQL Remote" dir=in action=allow protocol=TCP localport=3306

netsh advfirewall firewall add rule name="MySQL Remote Out" dir=out action=allow protocol=TCP localport=3306
```

**Verify Firewall Rule:**
```cmd
netsh advfirewall firewall show rule name="MySQL Remote"
```

#### 3.5 Verify MySQL is Listening

```cmd
netstat -an | findstr 3306
```

**Should show:**
```
TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING
```

**If shows:**
```
TCP    127.0.0.1:3306         0.0.0.0:0              LISTENING
```
Then my.ini wasn't updated correctly or MySQL wasn't restarted.

### Step 4: Get MySQL Laptop IP Address

```cmd
ipconfig
```

Look for **IPv4 Address** under your active network adapter (WiFi or Ethernet).

**Example:**
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.112.235
```

**Important:** Note this IP address - you'll need it on your laptop!

---

## PART 2: On Your Laptop (Development)

### Step 5: Test Connection to MySQL Laptop

#### 5.1 Test Ping

```cmd
ping 192.168.112.235
```

**Expected:**
```
Reply from 192.168.112.235: bytes=32 time=2ms TTL=128
```

**If "Request timed out":**
- Check both laptops on same WiFi
- Check MySQL laptop firewall
- Verify IP address is correct

#### 5.2 Test MySQL Connection (if you have MySQL client)

```cmd
mysql -h 192.168.112.235 -u root -proot123
```

**Expected:**
```
mysql>
```

**If successful:**
```sql
SHOW DATABASES;
USE fairdispatch;
SHOW TABLES;
SELECT COUNT(*) FROM users;
EXIT;
```

### Step 6: Verify Backend Configuration

Your `backend/app/database.py` should already have:

```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "root123")
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.112.235")
```

**This is already configured! ✅**

### Step 7: Restart Backend

The backend should auto-reload, but to be sure:

1. **Stop current backend:**
   - Go to terminal running uvicorn
   - Press `Ctrl + C`

2. **Start backend:**
   ```cmd
   cd d:\codethon\APP\fds\backend
   python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
   ```

3. **Look for success message:**
   ```
   🔌 Attempting to connect to database...
   ✅ Connected to MySQL database: fairdispatch
   📍 Host: 192.168.112.235:3306
   INFO:     Uvicorn running on http://127.0.0.1:8000
   ```

**If you see:**
```
⚠️ MySQL connection failed: ...
📦 Falling back to SQLite...
```
Then there's still a connection issue. Run diagnostics (Step 8).

### Step 8: Run Diagnostics (If Connection Fails)

```cmd
cd d:\codethon\APP\fds
diagnose_mysql.bat
```

This will test:
- Ping to MySQL server
- Port 3306 connectivity
- MySQL client connection
- Provide specific error messages

---

## PART 3: Verify Everything Works

### Step 9: Test API

**Open browser:**
```
http://127.0.0.1:8000
```

**Should return:**
```json
{
  "message": "FairDispatch AI API",
  "version": "2.0.0",
  "status": "running"
}
```

### Step 10: Check Database Connection

```cmd
cd backend
python test_db_connection.py
```

**Expected output:**
```
✅ Database connection successful!
✅ Using MySQL database
📊 Tables found (7):
  - admins
  - assignments
  - credit_logs
  - notifications
  - routes
  - users
  - weekly_policies
👥 Users in database: 5
🗺️  Routes in database: 6
```

### Step 11: Test with Your App

1. **Open your Flutter app** (should already be running)

2. **Login as Admin:**
   - Location ID: `LOC001`
   - Year: `2024`
   - DOB: `01011990`

3. **Check Dashboard:**
   - Should show 4 drivers
   - Should show 6 routes available

4. **Try "Run Dispatch":**
   - Click the lightning bolt button
   - Should create assignments

5. **Login as Driver:**
   - Logout
   - Login with:
     - Employee ID: `EMP002`
     - Password: `pass123`
   - Should see assigned route

---

## Troubleshooting

### Issue 1: "Can't connect to MySQL server"

**Check on MySQL Laptop:**
```cmd
# Is MySQL running?
net start | findstr MySQL

# Is it listening on all interfaces?
netstat -an | findstr 3306
# Should show: 0.0.0.0:3306

# Is firewall allowing it?
netsh advfirewall firewall show rule name="MySQL Remote"
```

**Check on Your Laptop:**
```cmd
# Can you ping it?
ping 192.168.112.235

# Can you telnet to port 3306?
telnet 192.168.112.235 3306
```

### Issue 2: "Access denied for user 'root'"

**On MySQL Laptop:**
```sql
mysql -u root -proot123

-- Check user permissions
SELECT user, host FROM mysql.user WHERE user='root';

-- Re-grant if needed
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'root123';
FLUSH PRIVILEGES;
```

### Issue 3: "Unknown database 'fairdispatch'"

**On MySQL Laptop:**
```sql
mysql -u root -proot123

SHOW DATABASES;
-- If fairdispatch not listed:
CREATE DATABASE fairdispatch;

-- Then import schema again
EXIT;
mysql -u root -proot123 fairdispatch < database_setup.sql
```

### Issue 4: IP Address Changed

**On MySQL Laptop:**
```cmd
ipconfig
```

**Update on Your Laptop:**
Edit `backend/app/database.py` with new IP

---

## Quick Reference Commands

### MySQL Laptop:
```cmd
# Start MySQL
net start MySQL80

# Check MySQL status
net start | findstr MySQL

# Check listening ports
netstat -an | findstr 3306

# Get IP address
ipconfig

# Login to MySQL
mysql -u root -proot123

# Import schema
mysql -u root -proot123 fairdispatch < database_setup.sql
```

### Your Laptop:
```cmd
# Test connection
ping 192.168.112.235
mysql -h 192.168.112.235 -u root -proot123

# Start backend
cd backend
python -m uvicorn app.main:app --reload

# Test database
python test_db_connection.py

# Run diagnostics
diagnose_mysql.bat
```

---

## Success Checklist

### On MySQL Laptop:
- [ ] MySQL installed and running
- [ ] Database 'fairdispatch' created
- [ ] Schema imported (7 tables, sample data)
- [ ] my.ini updated (bind-address = 0.0.0.0)
- [ ] MySQL restarted
- [ ] Remote access granted (root@%)
- [ ] Firewall configured (port 3306)
- [ ] IP address noted (192.168.112.235)

### On Your Laptop:
- [ ] Can ping MySQL laptop
- [ ] Can connect with MySQL client
- [ ] database.py configured correctly
- [ ] Backend shows "Connected to MySQL"
- [ ] API returns data
- [ ] App loads drivers and routes

---

## Final Verification

When everything is working, you should see:

**Backend Terminal:**
```
✅ Connected to MySQL database: fairdispatch
📍 Host: 192.168.112.235:3306
```

**App:**
- Admin dashboard shows 4 drivers
- 6 routes available
- Can run dispatch
- Driver can see assignments

**MySQL Laptop:**
```sql
mysql -u root -proot123 fairdispatch
SELECT COUNT(*) FROM assignments;
-- Should show assignments created by dispatch
```

---

## 🎉 You're Done!

Your FairDispatch AI is now running with:
- ✅ MySQL database on separate laptop
- ✅ Backend on your development laptop
- ✅ App connecting to remote database
- ✅ All features working

**Now focus on your demo! 🚀**
