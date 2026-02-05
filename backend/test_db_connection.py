"""
Test MySQL Database Connection
"""
import sys
sys.path.append('.')

from app.database import engine, DATABASE_URL, MYSQL_HOST, MYSQL_DATABASE

print("=" * 50)
print("Database Connection Test")
print("=" * 50)
print(f"Database URL: {DATABASE_URL}")
print(f"MySQL Host: {MYSQL_HOST}")
print(f"MySQL Database: {MYSQL_DATABASE}")
print("=" * 50)

try:
    # Test connection
    with engine.connect() as conn:
        result = conn.execute("SELECT 1")
        print("✅ Database connection successful!")
        
        # Check if we're using MySQL or SQLite
        if "mysql" in DATABASE_URL.lower():
            print("✅ Using MySQL database")
            
            # Check tables
            result = conn.execute("SHOW TABLES")
            tables = [row[0] for row in result]
            print(f"\n📊 Tables found ({len(tables)}):")
            for table in tables:
                print(f"  - {table}")
            
            # Check users count
            result = conn.execute("SELECT COUNT(*) FROM users")
            user_count = result.fetchone()[0]
            print(f"\n👥 Users in database: {user_count}")
            
            # Check routes count
            result = conn.execute("SELECT COUNT(*) FROM routes")
            route_count = result.fetchone()[0]
            print(f"🗺️  Routes in database: {route_count}")
            
            # Check assignments count
            result = conn.execute("SELECT COUNT(*) FROM assignments")
            assignment_count = result.fetchone()[0]
            print(f"📋 Assignments in database: {assignment_count}")
            
        else:
            print("⚠️  Using SQLite fallback")
            
            # Check tables for SQLite
            result = conn.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in result]
            print(f"\n📊 Tables found ({len(tables)}):")
            for table in tables:
                print(f"  - {table}")
        
        print("\n" + "=" * 50)
        print("✅ Test completed successfully!")
        print("=" * 50)
        
except Exception as e:
    print(f"\n❌ Connection failed: {str(e)}")
    print("\nTroubleshooting:")
    print("1. Check MySQL is running on 192.168.112.235")
    print("2. Verify password is correct (root123)")
    print("3. Ensure database 'fairdispatch' exists")
    print("4. Check firewall allows port 3306")
    print("5. Verify both laptops are on same network")
    print("\n" + "=" * 50)
