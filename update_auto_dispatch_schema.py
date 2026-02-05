import mysql.connector
import os

def update_weekly_policy_schema():
    print("Updating weekly_policies table with auto-dispatch columns...")
    
    try:
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="AIML25",
            database="fairdispatch"
        )
        cursor = conn.cursor()
        
        # Add auto_dispatch_enabled
        try:
            cursor.execute("ALTER TABLE weekly_policies ADD COLUMN auto_dispatch_enabled BOOLEAN DEFAULT FALSE")
            print("Added auto_dispatch_enabled column.")
        except mysql.connector.Error as err:
            print(f"Column auto_dispatch_enabled might already exist: {err}")
            
        # Add auto_dispatch_time
        try:
            cursor.execute("ALTER TABLE weekly_policies ADD COLUMN auto_dispatch_time VARCHAR(10) DEFAULT '08:00'")
            print("Added auto_dispatch_time column.")
        except mysql.connector.Error as err:
            print(f"Column auto_dispatch_time might already exist: {err}")
            
        conn.commit()
        cursor.close()
        conn.close()
        print("Schema update completed successfully.")
        
    except Exception as e:
        print(f"Error updating database: {e}")

if __name__ == "__main__":
    update_weekly_policy_schema()
