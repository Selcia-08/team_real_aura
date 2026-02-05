from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# Database Configuration
# Set your MySQL credentials here or use environment variable
MYSQL_USER = os.getenv("MYSQL_USER", "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "AIML25")  # MySQL password
MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")  # Local MySQL server
MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "fairdispatch")

# Construct MySQL URL
MYSQL_URL = f"mysql+mysqlconnector://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}"

# Allow override via environment variable
DATABASE_URL = os.getenv("DATABASE_URL", MYSQL_URL)

print(f"Attempting to connect to database...")

# Try MySQL first, fallback to SQLite
try:
    engine = create_engine(
        DATABASE_URL,
        echo=False,
        pool_pre_ping=True,  # Verify connections before using
        pool_recycle=3600,   # Recycle connections after 1 hour
    )
    # Test connection
    with engine.connect() as conn:
        print(f"Connected to MySQL database: {MYSQL_DATABASE}")
        print(f"Host: {MYSQL_HOST}:{MYSQL_PORT}")
except Exception as e:
    print(f"MySQL connection failed: {str(e)}")
    print("Falling back to SQLite...")
    DATABASE_URL = "sqlite:///./fairdispatch.db"
    engine = create_engine(
        DATABASE_URL,
        echo=False,
        connect_args={"check_same_thread": False}
    )
    print("Using SQLite database: fairdispatch.db")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
