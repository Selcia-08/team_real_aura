# 🚀 Complete MySQL Setup - Step by Step

## On the MySQL Laptop (Where MySQL is Installed)

### Step 1: Open MySQL Command Line

```bash
# Windows: Open "MySQL 8.0 Command Line Client"
# Or use Command Prompt:
mysql -u root -p
# Enter your MySQL root password
```

### Step 2: Run the Setup Script

**Option A: From File (Recommended)**
```bash
# Exit MySQL first if you're in it
EXIT;

# Run the setup script
mysql -u root -p < D:\codethon\APP\fds\database_setup.sql

# You should see:
# - Database created
# - Tables created
# - Data inserted
```

**Option B: Copy-Paste (If file transfer is difficult)**
```bash
# Stay in MySQL command line
# Copy the entire content of database_setup.sql
# Paste it into MySQL command line
# Press Enter
```

### Step 3: Verify Setup

```sql
-- Login to MySQL
mysql -u root -p

-- Check database
SHOW DATABASES;
-- You should see 'fairdispatch'

-- Use the database
USE fairdispatch;

-- Check tables
SHOW TABLES;
-- You should see 7 tables:
-- admins, assignments, credit_logs, notifications,
-- routes, users, weekly_policies

-- Check sample data
SELECT COUNT(*) FROM users;
-- Should return 5

SELECT COUNT(*) FROM routes;
-- Should return 6

-- View drivers
SELECT name, employee_id, fatigue_score, health_status FROM users WHERE role = 'DRIVER';
-- Should show 4 drivers
```

### Step 4: Enable Remote Access (If using from another laptop)

**Edit MySQL Configuration:**

1. Find `my.ini` file:
   - Windows: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
   - Or search for "my.ini" in MySQL installation folder

2. Open with Notepad (as Administrator)

3. Find this line:
   ```ini
   bind-address = 127.0.0.1
   ```

4. Change to:
   ```ini
   bind-address = 0.0.0.0
   ```

5. Save and close

**Grant Remote Access:**
```sql
-- In MySQL command line
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'your_password';
FLUSH PRIVILEGES;
```

**Restart MySQL:**
```bash
# Windows (as Administrator)
net stop MySQL80
net start MySQL80
```

**Allow Firewall:**
```bash
# Windows (as Administrator)
netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
```

**Find IP Address:**
```bash
ipconfig
# Note the IPv4 Address (e.g., 192.168.1.100)
```

---

## On Your Development Laptop (Where Backend is Running)

### Step 5: Configure Backend Connection

**Edit `backend/app/database.py`:**

Find lines 9-10 and update:
```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "YOUR_MYSQL_PASSWORD")
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.1.100")  # MySQL laptop IP
```

**Example:**
```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "MyPass123")
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.1.100")
```

### Step 6: Test Connection

**Test Ping:**
```bash
ping 192.168.1.100
# Should get replies
```

**Test MySQL Connection:**
```bash
mysql -h 192.168.1.100 -u root -p
# Enter password
# If successful: mysql>
```

### Step 7: Restart Backend

```bash
# Stop current backend (Ctrl+C in terminal)

# Start backend
cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

**Expected Output:**
```
🔌 Attempting to connect to database...
✅ Connected to MySQL database: fairdispatch
📍 Host: 192.168.1.100:3306
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### Step 8: Verify Backend Connection

**Test API:**
```bash
# Open browser or use curl
curl http://127.0.0.1:8000
```

**Should return:**
```json
{
  "message": "FairDispatch AI API",
  "version": "2.0.0",
  "status": "running"
}
```

### Step 9: Test with App

1. **Open your Flutter app** (already running)
2. **Login as Admin:**
   - Location ID: `LOC001`
   - Year: `2024`
   - DOB: `01011990`
3. **Check if data loads** (should see 4 drivers)
4. **Try "Run Dispatch"** button
5. **Login as Driver:**
   - Employee ID: `EMP002`
   - Password: `pass123`
6. **Check if route appears**

---

## Troubleshooting

### ❌ Error: "Can't connect to MySQL server"

**Check:**
1. MySQL is running on MySQL laptop
2. IP address is correct
3. Both laptops on same network
4. Firewall allows port 3306

**Solution:**
```bash
# On MySQL laptop
netstat -an | findstr 3306
# Should show: 0.0.0.0:3306 or *:3306
```

### ❌ Error: "Access denied for user 'root'@'your-ip'"

**Solution:**
```sql
-- On MySQL laptop
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

### ❌ Error: "Unknown database 'fairdispatch'"

**Solution:**
```sql
-- Run setup script again
mysql -u root -p < database_setup.sql
```

### ❌ Backend still using SQLite

**Check:**
- Password is correct in `database.py`
- IP address is correct
- MySQL is accessible from your laptop

**Fallback is OK!**
- SQLite works perfectly for demo
- Fix MySQL later if needed

---

## Quick Commands Reference

### MySQL Laptop Commands:
```bash
# Start MySQL
net start MySQL80

# Stop MySQL
net stop MySQL80

# Login to MySQL
mysql -u root -p

# Run setup script
mysql -u root -p < database_setup.sql

# Find IP
ipconfig
```

### Development Laptop Commands:
```bash
# Test connection
ping 192.168.1.100
mysql -h 192.168.1.100 -u root -p

# Start backend
cd backend
python -m uvicorn app.main:app --reload
```

### MySQL Commands:
```sql
-- View databases
SHOW DATABASES;

-- Use database
USE fairdispatch;

-- View tables
SHOW TABLES;

-- View data
SELECT * FROM users;
SELECT * FROM routes;
SELECT * FROM assignments;

-- Count records
SELECT COUNT(*) FROM users;
```

---

## Files Created for You

1. **database_setup.sql** - Complete database setup script
2. **DATABASE_QUERIES.md** - Common SQL queries reference
3. **REMOTE_MYSQL_SETUP.md** - Detailed remote setup guide
4. **connect_remote_mysql.bat** - Automated connection script

---

## Summary Checklist

### On MySQL Laptop:
- [ ] MySQL installed and running
- [ ] Ran `database_setup.sql`
- [ ] Verified 7 tables created
- [ ] Verified sample data inserted
- [ ] Enabled remote access (if needed)
- [ ] Configured firewall
- [ ] Noted IP address

### On Development Laptop:
- [ ] Updated `database.py` with password and IP
- [ ] Can ping MySQL laptop
- [ ] Backend restarted
- [ ] Sees "Connected to MySQL" message
- [ ] App loads data successfully

---

## 🎉 Success Indicators

You'll know it's working when you see:

1. **Backend logs:**
   ```
   ✅ Connected to MySQL database: fairdispatch
   📍 Host: 192.168.1.100:3306
   ```

2. **App shows:**
   - 4 drivers in admin dashboard
   - 6 routes available
   - Assignments can be created

3. **MySQL has data:**
   ```sql
   SELECT COUNT(*) FROM users;  -- Returns 5
   SELECT COUNT(*) FROM routes; -- Returns 6
   ```

---

**You're all set! Your FairDispatch AI system is now connected to MySQL!** 🚀

**Next:** Test all features and practice your demo!
