from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL

engine = create_engine(DATABASE_URL)
with engine.connect() as conn:
    res = conn.execute(text("SHOW CREATE TABLE assignments"))
    print(res.fetchone()[1])
