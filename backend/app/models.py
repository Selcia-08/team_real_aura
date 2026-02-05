from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Enum, Boolean, Text
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
import enum
from datetime import datetime

Base = declarative_base()

class HealthStatus(enum.Enum):
    NORMAL = "NORMAL"
    CAUTION = "CAUTION"
    RESTRICTED = "RESTRICTED"

class RouteGrade(enum.IntEnum):
    EASY = 1
    MEDIUM = 2
    HARD = 3

class UserRole(enum.Enum):
    DRIVER = "DRIVER"
    DISPATCHER = "DISPATCHER"
    ADMIN = "ADMIN"

class AssignmentStatus(enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    DECLINED = "DECLINED"
    REASSIGNED = "REASSIGNED"
    COMPLETED = "COMPLETED"

class Admin(Base):
    __tablename__ = "admins"
    
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(String(50), unique=True, index=True)
    year = Column(String(4))
    dob = Column(String(10))  # Format: DDMMYYYY
    name = Column(String(100))
    email = Column(String(100))

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    employee_id = Column(String(50), unique=True, index=True)
    password = Column(String(100))  # In production, hash this!
    name = Column(String(100))
    email = Column(String(100), unique=True, index=True)
    role = Column(Enum(UserRole), default=UserRole.DRIVER)
    location_id = Column(String(50))
    
    # Driver/Dispatcher specific fields
    fatigue_score = Column(Float, default=0.0) # 0 to 100
    health_status = Column(Enum(HealthStatus), default=HealthStatus.NORMAL)
    credits = Column(Integer, default=0)
    bonus_credits = Column(Integer, default=0)
    is_available = Column(Boolean, default=True)
    
    # Relaxation conditions
    has_medical_exemption = Column(Boolean, default=False)
    exemption_reason = Column(Text, nullable=True)
    exemption_until = Column(DateTime, nullable=True)

    # Extended Profile
    age = Column(Integer, nullable=True)
    dob = Column(String(20), nullable=True)
    native_place = Column(String(255), nullable=True)
    experience_years = Column(Integer, default=0)
    license_type = Column(String(50), nullable=True)
    photo_url = Column(Text, nullable=True)
    
    assignments = relationship("Assignment", back_populates="driver", foreign_keys="Assignment.driver_id")
    credit_logs = relationship("CreditLog", back_populates="driver")
    notifications = relationship("Notification", back_populates="user")

class Route(Base):
    __tablename__ = "routes"

    id = Column(Integer, primary_key=True, index=True)
    description = Column(String(255))
    area = Column(String(100))
    location_id = Column(String(50))
    
    # GPS Coordinates
    start_lat = Column(Float)
    start_lng = Column(Float)
    end_lat = Column(Float)
    end_lng = Column(Float)
    
    # Grading Factors
    package_count = Column(Integer)
    weight_kg = Column(Float)
    has_elevator = Column(Boolean, default=True)
    traffic_level = Column(Float) # 0.0 to 1.0
    apartment_density = Column(Float) # 0.0 to 1.0
    walking_distance_km = Column(Float)
    stairs_count = Column(Integer, default=0)
    parking_difficulty = Column(Float, default=0.5) # 0.0 to 1.0
    
    # ML/AI Predictions
    predicted_time_minutes = Column(Integer)
    terrain_difficulty = Column(Float) # From satellite analysis
    
    # Calculated Grade
    grade = Column(Enum(RouteGrade))
    grade_reason = Column(Text)  # Why this grade was assigned
    route_score = Column(Integer)  # Calculated route difficulty score
    route_credits = Column(Integer)  # Credits awarded for completing this route (1, 2, or 3)
    
    # Route Status
    is_assigned = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.now)
    
    assignments = relationship("Assignment", back_populates="route")

class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("users.id"))
    route_id = Column(Integer, ForeignKey("routes.id"))
    assigned_date = Column(DateTime, default=datetime.now)
    status = Column(Enum(AssignmentStatus), default=AssignmentStatus.PENDING)
    
    # Assignment explanation
    explanation = Column(Text)
    assignment_reason = Column(Text)  # Detailed reason for this specific driver
    
    # Response tracking
    response_time = Column(DateTime, nullable=True)
    decline_reason = Column(Text, nullable=True)
    
    # Reassignment tracking
    original_driver_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    reassignment_bonus = Column(Integer, default=0)
    
    # Completion tracking
    completed_at = Column(DateTime, nullable=True)
    actual_time_minutes = Column(Integer, nullable=True)
    
    driver = relationship("User", back_populates="assignments", foreign_keys=[driver_id])
    original_driver = relationship("User", foreign_keys=[original_driver_id])
    route = relationship("Route", back_populates="assignments")

class CreditLog(Base):
    __tablename__ = "credit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    driver_id = Column(Integer, ForeignKey("users.id"))
    amount = Column(Integer)
    reason = Column(String(255))
    is_bonus = Column(Boolean, default=False)
    timestamp = Column(DateTime, default=datetime.now)
    
    driver = relationship("User", back_populates="credit_logs")

class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String(200))
    message = Column(Text)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.now)
    notification_type = Column(String(50))  # route_assigned, route_declined, bonus, etc.
    
    user = relationship("User", back_populates="notifications")

class WeeklyPolicy(Base):
    __tablename__ = "weekly_policies"
    
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(String(50))
    easy_routes_target = Column(Integer, default=2)
    medium_routes_target = Column(Integer, default=3)
    hard_routes_target = Column(Integer, default=2)
    
    # Credit rewards
    easy_route_credits = Column(Integer, default=3)
    medium_route_credits = Column(Integer, default=4)
    hard_route_credits = Column(Integer, default=6)
    
    # Relaxation conditions
    max_consecutive_hard_routes = Column(Integer, default=2)
    min_rest_days_after_hard = Column(Integer, default=1)
    fatigue_threshold_for_restriction = Column(Float, default=80.0)
    
    # Auto-dispatch scheduling
    auto_dispatch_enabled = Column(Boolean, default=False)
    auto_dispatch_time = Column(String(10), default="08:00") # Format: "HH:MM"
    
    updated_at = Column(DateTime, default=datetime.now)
    updated_by = Column(String(100))

class DailyReport(Base):
    __tablename__ = "daily_reports"
    
    id = Column(Integer, primary_key=True, index=True)
    report_date = Column(DateTime, default=datetime.now)
    location_id = Column(String(50))
    pdf_path = Column(Text)
    assignments_count = Column(Integer)
    created_at = Column(DateTime, default=datetime.now)
