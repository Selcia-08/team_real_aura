# 🌐 Remote MySQL Configuration Guide

## Connecting to MySQL on Another Laptop

### Step 1: Configure MySQL Server (On the MySQL Laptop)

#### 1.1 Create Database
```sql
mysql -u root -p
CREATE DATABASE fairdispatch;
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'your_password';
FLUSH PRIVILEGES;
EXIT;
```

#### 1.2 Enable Remote Access

Edit MySQL configuration file:

**Windows:** `C:\ProgramData\MySQL\MySQL Server 8.0\my.ini`
**Linux:** `/etc/mysql/mysql.conf.d/mysqld.cnf`

Find and change:
```ini
# FROM:
bind-address = 127.0.0.1

# TO:
bind-address = 0.0.0.0
```

#### 1.3 Restart MySQL Service

**Windows:**
```bash
net stop MySQL80
net start MySQL80
```

**Linux:**
```bash
sudo systemctl restart mysql
```

#### 1.4 Configure Firewall

**Windows Firewall:**
```bash
netsh advfirewall firewall add rule name="MySQL" dir=in action=allow protocol=TCP localport=3306
```

**Linux (UFW):**
```bash
sudo ufw allow 3306/tcp
```

#### 1.5 Find MySQL Server IP Address

**Windows:**
```bash
ipconfig
# Look for IPv4 Address (e.g., 192.168.1.100)
```

**Linux:**
```bash
ip addr show
# or
hostname -I
```

---

### Step 2: Configure FairDispatch Backend (On Your Current Laptop)

#### 2.1 Update database.py

Edit `backend/app/database.py`:

```python
# Line 9-13: Update these values
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "your_mysql_password")  # ← SET THIS
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.1.100")  # ← MySQL laptop IP
MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "fairdispatch")
```

**Example:**
```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "MySecurePass123")
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.1.100")
```

#### 2.2 Test Connection

```bash
# From your current laptop, test if you can reach MySQL
ping 192.168.1.100

# Test MySQL connection
mysql -h 192.168.1.100 -u root -p
# Enter password
# If successful, you'll see: mysql>
```

#### 2.3 Restart Backend

```bash
# Stop current backend (Ctrl+C in the terminal)
cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

You should see:
```
🔌 Attempting to connect to database...
✅ Connected to MySQL database: fairdispatch
📍 Host: 192.168.1.100:3306
```

---

### Step 3: Quick Setup Using Environment Variables

Instead of editing the file, you can use environment variables:

**Windows (PowerShell):**
```powershell
$env:MYSQL_PASSWORD="your_password"
$env:MYSQL_HOST="192.168.1.100"
cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

**Windows (CMD):**
```cmd
set MYSQL_PASSWORD=your_password
set MYSQL_HOST=192.168.1.100
cd backend
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

---

### Step 4: Verify Connection

#### Check Backend Logs
You should see:
```
🔌 Attempting to connect to database...
✅ Connected to MySQL database: fairdispatch
📍 Host: 192.168.1.100:3306
```

#### Test API
Visit: http://127.0.0.1:8000

Should return:
```json
{
  "message": "FairDispatch AI API",
  "version": "2.0.0",
  "status": "running"
}
```

#### Populate Demo Data
1. Open app
2. Login as admin
3. Click "Populate Demo Data"
4. Check MySQL laptop to verify data

---

### Troubleshooting

#### Error: Can't connect to MySQL server on '192.168.1.100'

**Solutions:**
1. **Check both laptops are on same network**
   ```bash
   ping 192.168.1.100
   ```

2. **Verify MySQL is running on remote laptop**
   ```bash
   # On MySQL laptop
   netstat -an | findstr 3306
   ```

3. **Check firewall allows port 3306**
   - Windows: Check Windows Defender Firewall
   - Router: Check if port forwarding needed

4. **Verify MySQL user has remote access**
   ```sql
   SELECT user, host FROM mysql.user WHERE user='root';
   ```

#### Error: Access denied for user 'root'@'your-ip'

**Solution:**
```sql
# On MySQL laptop
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

#### Error: Host 'your-ip' is not allowed to connect

**Solution:**
```sql
# On MySQL laptop
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
FLUSH PRIVILEGES;
```

---

### Security Considerations

#### For Demo (Same Local Network):
- ✅ Use simple password
- ✅ Allow all hosts (%)
- ✅ No SSL required

#### For Production:
- 🔒 Use strong passwords
- 🔒 Limit specific IPs only
- 🔒 Enable SSL/TLS
- 🔒 Use dedicated user (not root)

---

### Alternative: Use SSH Tunnel (More Secure)

If you want extra security:

```bash
# Create SSH tunnel from your laptop to MySQL laptop
ssh -L 3306:localhost:3306 user@192.168.1.100

# Then in database.py, use:
MYSQL_HOST = "localhost"  # Tunnel redirects to remote
```

---

### Quick Reference

#### MySQL Laptop Setup Checklist:
- [ ] MySQL installed and running
- [ ] Database 'fairdispatch' created
- [ ] Remote access enabled (bind-address = 0.0.0.0)
- [ ] Firewall allows port 3306
- [ ] User has remote access permissions
- [ ] IP address noted (e.g., 192.168.1.100)

#### Your Laptop Setup Checklist:
- [ ] Can ping MySQL laptop
- [ ] database.py updated with correct IP and password
- [ ] Backend restarted
- [ ] Connection successful message shown

---

### Example Configuration

**Scenario:** 
- MySQL Laptop IP: 192.168.1.100
- MySQL Password: Demo123
- Both on same WiFi network

**On MySQL Laptop:**
```sql
CREATE DATABASE fairdispatch;
GRANT ALL PRIVILEGES ON fairdispatch.* TO 'root'@'%' IDENTIFIED BY 'Demo123';
FLUSH PRIVILEGES;
```

**On Your Laptop (database.py):**
```python
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "Demo123")
MYSQL_HOST = os.getenv("MYSQL_HOST", "192.168.1.100")
```

**Restart backend and you're done!** ✅

---

### Need Help?

1. **Can't find MySQL laptop IP?**
   - On MySQL laptop: `ipconfig` (Windows) or `ip addr` (Linux)

2. **Connection timeout?**
   - Check firewall on both laptops
   - Ensure both on same network

3. **Access denied?**
   - Verify password is correct
   - Check user has remote access

4. **Still not working?**
   - Use SQLite fallback (already configured!)
   - Focus on demo, fix MySQL later

---

**Remember:** SQLite fallback is automatic. If MySQL connection fails, the system will use SQLite. This is the safest option for your demo! 🚀
