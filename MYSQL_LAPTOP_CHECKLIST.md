# ✅ MySQL Laptop Setup Checklist

## Quick Setup Guide for MySQL Laptop (192.168.112.235)

Follow these steps IN ORDER on the laptop where MySQL is installed.

---

## Step 1: Import Database Schema ⭐ MOST IMPORTANT

```cmd
# Open Command Prompt
cd path\to\database_setup.sql

# Import the schema
mysql -u root -proot123 fairdispatch < database_setup.sql
```

**If database doesn't exist:**
```cmd
mysql -u root -proot123
CREATE DATABASE fairdispatch;
EXIT;

mysql -u root -proot123 fairdispatch < database_setup.sql
```

**Verify:**
```cmd
mysql -u root -proot123 fairdispatch
SHOW TABLES;
SELECT COUNT(*) FROM users;
-- Should show 5
EXIT;
```

---

## Step 2: Enable Remote Access

### 2.1 Edit my.ini

1. Find file: `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
2. Open as Administrator (Notepad)
3. Find: `bind-address = 127.0.0.1`
4. Change to: `bind-address = 0.0.0.0`
5. Save and close

### 2.2 Grant Remote Permissions

```cmd
mysql -u root -proot123

GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'root123';
FLUSH PRIVILEGES;
EXIT;
```

### 2.3 Restart MySQL

```cmd
# Run as Administrator
net stop MySQL80
net start MySQL80
```

---

## Step 3: Configure Firewall

```cmd
# Run as Administrator
netsh advfirewall firewall add rule name="MySQL Remote" dir=in action=allow protocol=TCP localport=3306
```

---

## Step 4: Verify Setup

### 4.1 Check MySQL is Listening

```cmd
netstat -an | findstr 3306
```

**Should show:**
```
TCP    0.0.0.0:3306           0.0.0.0:0              LISTENING
```

### 4.2 Get IP Address

```cmd
ipconfig
```

Note the IPv4 Address (should be 192.168.112.235)

### 4.3 Test Locally

```cmd
mysql -u root -proot123 fairdispatch
SELECT * FROM users;
EXIT;
```

---

## Step 5: Test from Your Other Laptop

On your development laptop, run:

```cmd
ping 192.168.112.235
mysql -h 192.168.112.235 -u root -proot123
```

If successful, you're done! ✅

---

## Quick Commands Reference

```cmd
# Check MySQL is running
net start | findstr MySQL

# Start MySQL
net start MySQL80

# Stop MySQL
net stop MySQL80

# Restart MySQL
net stop MySQL80 && net start MySQL80

# Login to MySQL
mysql -u root -proot123

# Check database
mysql -u root -proot123 fairdispatch -e "SHOW TABLES;"

# Count records
mysql -u root -proot123 fairdispatch -e "SELECT COUNT(*) FROM users;"

# View all drivers
mysql -u root -proot123 fairdispatch -e "SELECT name, employee_id, health_status FROM users WHERE role='DRIVER';"

# Get IP address
ipconfig | findstr IPv4
```

---

## Troubleshooting

### MySQL won't start
```cmd
# Check error log
type "C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err"
```

### Can't find my.ini
```cmd
# Search for it
dir /s C:\ProgramData\my.ini
dir /s "C:\Program Files\MySQL\my.ini"
```

### Firewall blocking
```cmd
# Disable Windows Firewall temporarily (for testing)
netsh advfirewall set allprofiles state off

# Re-enable after testing
netsh advfirewall set allprofiles state on
```

### Wrong IP address
```cmd
# Get correct IP
ipconfig

# Update on development laptop:
# Edit backend/app/database.py
# Change MYSQL_HOST to new IP
```

---

## Files You Need

1. **database_setup.sql** - Copy this file to MySQL laptop
   - Contains all table definitions
   - Contains sample data
   - Run this FIRST

---

## Expected Results

After completing all steps:

✅ MySQL running on port 3306
✅ Database 'fairdispatch' exists
✅ 7 tables created
✅ 5 users, 6 routes inserted
✅ Remote access enabled
✅ Firewall configured
✅ Can connect from other laptop

---

## Next Steps

After MySQL laptop is set up:

1. On your development laptop:
   - Backend should auto-connect
   - Look for: "✅ Connected to MySQL database"

2. Test with app:
   - Login as admin
   - Should see 4 drivers
   - Run dispatch
   - Login as driver
   - See assigned route

---

## 🎯 Priority Order

If short on time, do these in order:

1. ⭐ Import database_setup.sql (MUST DO)
2. ⭐ Edit my.ini bind-address (MUST DO)
3. ⭐ Grant remote access (MUST DO)
4. ⭐ Restart MySQL (MUST DO)
5. Configure firewall (Important)
6. Test connection (Verify)

---

**Total Time: 10-15 minutes**

**Good luck! 🚀**
