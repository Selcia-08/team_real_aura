# ✅ Database Setup - FairDispatch AI

## Current Status: SQLite (Working Perfectly!)

Your system is currently using **SQLite** which is:
- ✅ **Already working** - No setup needed
- ✅ **Perfect for demos** - Fast and reliable
- ✅ **Zero configuration** - Just works
- ✅ **Portable** - Single file database

**For your hackathon demo, SQLite is the BEST choice!**

---

## Option 1: Keep Using SQLite (Recommended for Demo)

### Why SQLite is Perfect for Your Demo:
1. ✅ **No installation required** - Already working
2. ✅ **No configuration needed** - Zero setup time
3. ✅ **Fast** - Great performance for demos
4. ✅ **Reliable** - No connection issues
5. ✅ **Portable** - Easy to backup/restore

### Current Setup:
- Database file: `backend/fairdispatch.db`
- Auto-created on first run
- All features working perfectly

### You're all set! No action needed. 🎉

---

## Option 2: Install MySQL (For Production Later)

If you want to use MySQL in the future, here's how:

### Step 1: Download MySQL
Visit: https://dev.mysql.com/downloads/mysql/
- Choose: MySQL Community Server
- Version: 8.0 or later
- Platform: Windows

### Step 2: Install MySQL
1. Run the installer
2. Choose "Developer Default" setup
3. Set root password (remember this!)
4. Complete installation

### Step 3: Create Database
```bash
# Open MySQL Command Line Client
# Enter your root password

CREATE DATABASE fairdispatch;
SHOW DATABASES;
EXIT;
```

### Step 4: Configure FairDispatch
Edit `backend/app/database.py` line 9:
```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "YOUR_PASSWORD_HERE")
```

### Step 5: Restart Backend
```bash
# Stop current backend (Ctrl+C)
cd backend
python -m uvicorn app.main:app --reload
```

You should see:
```
✅ Connected to MySQL database: fairdispatch
📍 Host: localhost:3306
```

---

## Comparison: SQLite vs MySQL

| Feature | SQLite | MySQL |
|---------|--------|-------|
| **Setup Time** | 0 minutes ✅ | 15-30 minutes |
| **Configuration** | None ✅ | Password, ports, etc. |
| **Demo Ready** | Yes ✅ | Requires setup |
| **Performance (Demo)** | Excellent ✅ | Excellent |
| **Performance (Production)** | Good | Better for scale |
| **Concurrent Users** | Limited | Unlimited |
| **Backup** | Copy file ✅ | mysqldump |
| **Portability** | Very high ✅ | Medium |

---

## For Your Hackathon Demo

### ✅ Recommendation: Stick with SQLite

**Why?**
1. It's already working perfectly
2. Zero setup time = more time to practice demo
3. No risk of connection issues during presentation
4. Judges won't care about database choice
5. All features work identically

### What Judges Care About:
- ✅ Your fairness algorithm
- ✅ UI/UX quality
- ✅ Feature completeness
- ✅ Demo smoothness
- ✅ Your presentation

### What Judges DON'T Care About:
- ❌ SQLite vs MySQL
- ❌ Database configuration
- ❌ Infrastructure details

---

## Current Backend Configuration

Your `backend/app/database.py` is configured to:

1. **Try MySQL first** at `localhost:3306`
2. **Automatically fallback to SQLite** if MySQL not available
3. **Print clear status messages**:
   ```
   🔌 Attempting to connect to database...
   ⚠️ MySQL connection failed: ...
   📦 Falling back to SQLite...
   ✅ Using SQLite database: fairdispatch.db
   ```

This is the **perfect setup** for your demo!

---

## Database File Location

```
backend/
├── app/
│   ├── main.py
│   ├── models.py
│   └── database.py
└── fairdispatch.db  ← Your SQLite database
```

### Backup Your Data
```bash
# Simple backup
copy backend\fairdispatch.db backend\fairdispatch_backup.db

# Restore
copy backend\fairdispatch_backup.db backend\fairdispatch.db
```

---

## Viewing Your Data

### Option 1: DB Browser for SQLite (GUI)
Download: https://sqlitebrowser.org/
1. Install DB Browser
2. Open `backend/fairdispatch.db`
3. Browse tables visually

### Option 2: Command Line
```bash
# Install SQLite command line (if not installed)
# Then:
cd backend
sqlite3 fairdispatch.db

# View tables
.tables

# View users
SELECT * FROM users;

# View routes
SELECT * FROM routes;

# Exit
.exit
```

### Option 3: Python Script
```python
import sqlite3

conn = sqlite3.connect('backend/fairdispatch.db')
cursor = conn.cursor()

# View all users
cursor.execute("SELECT * FROM users")
for row in cursor.fetchall():
    print(row)

conn.close()
```

---

## Migration to MySQL (Future)

When you're ready to move to production with MySQL:

1. **Export data from SQLite:**
   ```bash
   sqlite3 fairdispatch.db .dump > data.sql
   ```

2. **Import to MySQL:**
   ```bash
   mysql -u root -p fairdispatch < data.sql
   ```

3. **Update password in database.py**

4. **Restart backend**

---

## Troubleshooting

### Database is locked
```bash
# Close all connections
# Delete lock file
del backend\fairdispatch.db-journal
```

### Want to reset database
```bash
# Delete database file
del backend\fairdispatch.db

# Restart backend (will recreate)
cd backend
python -m uvicorn app.main:app --reload
```

### Check if database exists
```bash
dir backend\fairdispatch.db
```

---

## Summary

### For Your Demo: ✅ Use SQLite (Current Setup)
- Already working
- Zero configuration
- Perfect for hackathon
- No risk of issues

### For Future Production: Consider MySQL
- Better for many concurrent users
- Industry standard
- Easy to migrate later

---

## Your Action Items

### Before Demo:
- [x] Database working (SQLite)
- [x] Backend running
- [x] Frontend running
- [ ] Practice demo flow
- [ ] Test all features

### No database setup needed! You're ready to go! 🚀

---

**Questions?**
- Check TROUBLESHOOTING.md
- Or just keep using SQLite - it works great!
