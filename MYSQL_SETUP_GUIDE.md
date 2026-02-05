# 🗄️ MySQL Setup for FairDispatch AI

## Quick Setup (5 minutes)

### Step 1: Install MySQL (if not installed)
Download from: https://dev.mysql.com/downloads/mysql/

### Step 2: Create Database

Open MySQL command line or MySQL Workbench:

```sql
-- Login to MySQL
mysql -u root -p

-- Create database
CREATE DATABASE fairdispatch;

-- Verify
SHOW DATABASES;

-- Exit
EXIT;
```

### Step 3: Configure Password

**Option A: Edit database.py**
```python
# In backend/app/database.py, line 9:
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "YOUR_PASSWORD_HERE")
```

**Option B: Use Environment Variable (Recommended)**
```bash
# Windows
set MYSQL_PASSWORD=your_password

# Linux/Mac
export MYSQL_PASSWORD=your_password
```

### Step 4: Restart Backend

```bash
# Stop current backend (Ctrl+C)
cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

You should see:
```
✅ Connected to MySQL database: fairdispatch
📍 Host: localhost:3306
```

## Configuration Options

### Custom MySQL Settings

Edit `backend/app/database.py`:

```python
MYSQL_USER = "root"              # Your MySQL username
MYSQL_PASSWORD = "your_password" # Your MySQL password
MYSQL_HOST = "localhost"         # MySQL server host
MYSQL_PORT = "3306"              # MySQL server port
MYSQL_DATABASE = "fairdispatch"  # Database name
```

### Using Environment Variables

```bash
# Windows
set MYSQL_USER=root
set MYSQL_PASSWORD=your_password
set MYSQL_HOST=localhost
set MYSQL_PORT=3306
set MYSQL_DATABASE=fairdispatch

# Linux/Mac
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password
export MYSQL_HOST=localhost
export MYSQL_PORT=3306
export MYSQL_DATABASE=fairdispatch
```

## Verify MySQL Connection

### Check if MySQL is Running

```bash
# Windows
net start | findstr MySQL

# Linux
sudo systemctl status mysql

# Mac
brew services list | grep mysql
```

### Test Connection

```bash
mysql -u root -p
# Enter password when prompted
# If successful, you'll see: mysql>
```

### Check Database

```sql
SHOW DATABASES;
USE fairdispatch;
SHOW TABLES;
```

After first backend run, you should see:
- admins
- users
- routes
- assignments
- credit_logs
- notifications
- weekly_policies

## Troubleshooting

### Error: Access denied for user 'root'@'localhost'

**Solution:**
```sql
-- Reset MySQL root password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
FLUSH PRIVILEGES;
```

### Error: Can't connect to MySQL server

**Solutions:**
1. Check MySQL is running:
   ```bash
   # Windows
   net start MySQL80
   
   # Linux
   sudo systemctl start mysql
   ```

2. Check port 3306 is not blocked:
   ```bash
   netstat -an | findstr 3306
   ```

### Error: Database 'fairdispatch' doesn't exist

**Solution:**
```sql
CREATE DATABASE fairdispatch;
```

### Error: Unknown database 'fairdispatch'

**Solution:**
The database was not created. Run:
```sql
mysql -u root -p
CREATE DATABASE fairdispatch;
```

## SQLite Fallback

If MySQL setup is taking too long, the system automatically falls back to SQLite:

```
⚠️ MySQL connection failed: ...
📦 Falling back to SQLite...
✅ Using SQLite database: fairdispatch.db
```

This is **perfectly fine for demo purposes**! SQLite works great for development and demonstrations.

## Production Recommendations

For production deployment:

1. **Use MySQL** (better performance with multiple users)
2. **Create dedicated user** (don't use root):
   ```sql
   CREATE USER 'fairdispatch'@'localhost' IDENTIFIED BY 'secure_password';
   GRANT ALL PRIVILEGES ON fairdispatch.* TO 'fairdispatch'@'localhost';
   FLUSH PRIVILEGES;
   ```

3. **Enable SSL/TLS** for secure connections
4. **Regular backups**:
   ```bash
   mysqldump -u root -p fairdispatch > backup.sql
   ```

5. **Use connection pooling** (already configured in database.py)

## Current Status

Your backend is currently configured to:
1. ✅ Try MySQL first at `localhost:3306`
2. ✅ Automatically fallback to SQLite if MySQL unavailable
3. ✅ Use connection pooling for better performance
4. ✅ Verify connections before using (pool_pre_ping)

## Quick Commands Reference

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE fairdispatch;"

# Check tables
mysql -u root -p fairdispatch -e "SHOW TABLES;"

# Backup database
mysqldump -u root -p fairdispatch > backup.sql

# Restore database
mysql -u root -p fairdispatch < backup.sql

# Delete database (careful!)
mysql -u root -p -e "DROP DATABASE fairdispatch;"
```

---

**Need help?** Check TROUBLESHOOTING.md for common issues!
