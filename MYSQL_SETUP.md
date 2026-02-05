# MySQL Setup Guide for FairDispatch AI

## Option 1: Using MySQL (Recommended for Production)

### Step 1: Install MySQL
Download and install MySQL from: https://dev.mysql.com/downloads/mysql/

### Step 2: Create Database
```sql
-- Open MySQL command line or MySQL Workbench
mysql -u root -p

-- Create database
CREATE DATABASE fairdispatch;

-- Verify
SHOW DATABASES;

-- Exit
EXIT;
```

### Step 3: Configure Backend
Edit `backend/app/database.py`:

```python
DATABASE_URL = "mysql+mysqlconnector://root:YOUR_PASSWORD@localhost:3306/fairdispatch"
```

Replace `YOUR_PASSWORD` with your MySQL root password.

### Step 4: Test Connection
```bash
cd backend
python -c "from app.database import engine; engine.connect(); print('✅ MySQL Connected!')"
```

## Option 2: Using SQLite (Default - No Setup Required)

The system automatically falls back to SQLite if MySQL is not available.

- Database file: `fairdispatch.db` (auto-created in backend folder)
- No configuration needed
- Perfect for demo/development

## Verify Setup

### Check Database Tables
After running the backend for the first time:

**For MySQL:**
```sql
mysql -u root -p fairdispatch
SHOW TABLES;
```

You should see:
- admins
- users
- routes
- assignments
- credit_logs
- notifications
- weekly_policies

**For SQLite:**
```bash
# Install SQLite browser or use command line
sqlite3 fairdispatch.db
.tables
```

## Troubleshooting

### MySQL Connection Error
```
Error: Can't connect to MySQL server
```

**Solution:**
1. Check MySQL is running:
   ```bash
   # Windows
   net start MySQL80
   
   # Linux/Mac
   sudo systemctl start mysql
   ```

2. Verify credentials in `database.py`

3. Check firewall settings

### SQLite Fallback
If you see:
```
⚠️ MySQL connection failed: ...
📦 Falling back to SQLite...
```

This is normal! The system will use SQLite automatically.

## Production Recommendations

1. **Use MySQL** for better performance with multiple users
2. **Set up backups** regularly
3. **Use environment variables** for credentials:
   ```bash
   export DATABASE_URL="mysql+mysqlconnector://user:pass@localhost/fairdispatch"
   ```
4. **Enable SSL** for database connections
5. **Create separate user** (don't use root):
   ```sql
   CREATE USER 'fairdispatch'@'localhost' IDENTIFIED BY 'secure_password';
   GRANT ALL PRIVILEGES ON fairdispatch.* TO 'fairdispatch'@'localhost';
   FLUSH PRIVILEGES;
   ```

## Data Persistence

### Backup Database

**MySQL:**
```bash
mysqldump -u root -p fairdispatch > backup.sql
```

**SQLite:**
```bash
cp fairdispatch.db fairdispatch_backup.db
```

### Restore Database

**MySQL:**
```bash
mysql -u root -p fairdispatch < backup.sql
```

**SQLite:**
```bash
cp fairdispatch_backup.db fairdispatch.db
```
