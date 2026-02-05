import sys
sys.path.insert(0, 'd:/codethon/APP/fds')

from sqlalchemy import text
from backend.app.database import engine, MYSQL_HOST, MYSQL_DATABASE

print(f"🔌 Testing connection to {MYSQL_HOST}:{MYSQL_DATABASE}")

try:
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM users"))
        count = result.fetchone()[0]
        print(f"✅ Connection successful!")
        print(f"📊 Found {count} users in database")
except Exception as e:
    print(f"❌ Connection failed: {e}")
