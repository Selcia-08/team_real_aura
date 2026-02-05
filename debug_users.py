from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

def show_credentials():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        print("\n--- ADMINS ---")
        result = conn.execute(text("SELECT id, location_id, year, dob, name FROM admins"))
        for row in result:
            print(f"ID: {row.id} | Location: {row.location_id} | Year: {row.year} | DOB: {row.dob} | Name: {row.name}")
            
        print("\n--- DRIVERS ---")
        result = conn.execute(text("SELECT id, name, employee_id, password, email FROM users"))
        for row in result:
            print(f"ID: {row.id} | Name: {row.name} | EmpID: {row.employee_id} | Pass: {row.password} | Email: {row.email}")

if __name__ == "__main__":
    show_credentials()
