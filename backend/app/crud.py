from sqlalchemy.orm import Session
from . import models, schemas

import random

def get_user(db: Session, user_id: int):
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.User).offset(skip).limit(limit).all()

def create_user(db: Session, user: schemas.UserCreate):
    # Auto-generate ID if missing
    emp_id = user.employee_id
    if not emp_id:
        age_part = str(user.age) if user.age else "00"
        suffix = random.randint(100, 999)
        emp_id = f"EMP{age_part}{suffix}"
        
    # Auto-generate Password if missing (use DOB)
    pwd = user.password
    if not pwd:
        pwd = user.dob if user.dob else "pass123"

    db_user = models.User(
        name=user.name,
        email=user.email,
        employee_id=emp_id,
        password=pwd,
        role=user.role,
        location_id=user.location_id,
        # New profile fields
        age=user.age,
        dob=user.dob,
        native_place=user.native_place,
        experience_years=user.experience_years,
        license_type=user.license_type,
        photo_url=user.photo_url,
        # Defaults
        fatigue_score=0.0,
        health_status=models.HealthStatus.NORMAL,
        credits=10,
        bonus_credits=0,
        is_available=True
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_route(db: Session, route_id: int):
    return db.query(models.Route).filter(models.Route.id == route_id).first()

def get_routes(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Route).offset(skip).limit(limit).all()

def get_assignments(db: Session, driver_id: int = None):
    q = db.query(models.Assignment)
    if driver_id:
        q = q.filter(models.Assignment.driver_id == driver_id)
    return q.all()
