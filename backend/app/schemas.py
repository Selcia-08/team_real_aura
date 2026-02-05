from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from .models import RouteGrade, HealthStatus, UserRole, AssignmentStatus

# ============ AUTH SCHEMAS ============

class AdminLogin(BaseModel):
    location_id: str
    year: str
    dob: str  # DDMMYYYY

class DriverLogin(BaseModel):
    employee_id: str
    password: str

class LoginResponse(BaseModel):
    success: bool
    message: str
    user_id: Optional[int] = None
    role: Optional[str] = None
    token: Optional[str] = None

# ============ USER SCHEMAS ============

class UserBase(BaseModel):
    name: str
    email: str
    employee_id: Optional[str] = None
    role: UserRole = UserRole.DRIVER
    location_id: str
    # New fields
    age: Optional[int] = None
    dob: Optional[str] = None
    native_place: Optional[str] = None
    experience_years: Optional[int] = 0
    license_type: Optional[str] = None
    photo_url: Optional[str] = None

class UserCreate(UserBase):
    password: Optional[str] = None

class UserResponse(UserBase):
    id: int
    fatigue_score: float
    health_status: HealthStatus
    credits: int
    bonus_credits: int
    is_available: bool
    has_medical_exemption: bool
    
    class Config:
        from_attributes = True

# ============ ROUTE SCHEMAS ============

class RouteBase(BaseModel):
    description: str
    area: str
    location_id: str
    start_lat: float
    start_lng: float
    end_lat: float
    end_lng: float
    package_count: int
    weight_kg: float
    has_elevator: bool
    traffic_level: float
    apartment_density: float
    walking_distance_km: float
    stairs_count: int = 0
    parking_difficulty: float = 0.5

class RouteCreate(RouteBase):
    pass

class RouteResponse(RouteBase):
    id: int
    grade: Optional[RouteGrade] = None
    grade_reason: Optional[str] = None
    predicted_time_minutes: Optional[int] = None
    terrain_difficulty: Optional[float] = None
    is_assigned: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

# ============ ASSIGNMENT SCHEMAS ============

class AssignmentResponse(BaseModel):
    id: int
    driver_id: int
    route_id: int
    assigned_date: datetime
    status: AssignmentStatus
    explanation: str
    assignment_reason: str
    reassignment_bonus: int
    route: Optional[RouteResponse] = None
    
    class Config:
        from_attributes = True

class AssignmentAction(BaseModel):
    assignment_id: int
    action: str  # "accept" or "decline"
    decline_reason: Optional[str] = None

# ============ NOTIFICATION SCHEMAS ============

class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    is_read: bool
    created_at: datetime
    notification_type: str
    
    class Config:
        from_attributes = True

# ============ ADMIN SCHEMAS ============

class WeeklyPolicyUpdate(BaseModel):
    location_id: str
    easy_routes_target: Optional[int] = None
    medium_routes_target: Optional[int] = None
    hard_routes_target: Optional[int] = None
    easy_route_credits: Optional[int] = None
    medium_route_credits: Optional[int] = None
    hard_route_credits: Optional[int] = None
    max_consecutive_hard_routes: Optional[int] = None
    fatigue_threshold_for_restriction: Optional[float] = None
    auto_dispatch_enabled: Optional[bool] = None
    auto_dispatch_time: Optional[str] = None

class DriverStats(BaseModel):
    driver_id: int
    driver_name: str
    fatigue: float
    credits: int
    bonus_credits: int
    health_status: str
    weekly_balance: dict
    total_assignments: int
    pending_assignments: int

class DashboardStats(BaseModel):
    total_drivers: int
    active_drivers: int
    total_routes_today: int
    pending_assignments: int
    completed_today: int
    avg_fatigue: float
    drivers_needing_attention: List[DriverStats]
