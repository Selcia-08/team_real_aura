from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timedelta
from . import models, schemas, crud, database, logic, email_service, pdf_service
import random
import asyncio

models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="FairDispatch AI API",
    description="Human-centered, fairness-aware delivery dispatch system",
    version="2.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ============ AUTHENTICATION ENDPOINTS ============

@app.post("/auth/admin/login", response_model=schemas.LoginResponse)
def admin_login(credentials: schemas.AdminLogin, db: Session = Depends(get_db)):
    """Admin login using location_id, year, and DOB"""
    admin = db.query(models.Admin).filter(
        models.Admin.location_id == credentials.location_id
    ).first()
    
    if not admin:
        return schemas.LoginResponse(success=False, message="Invalid location ID")
    
    if admin.year != credentials.year or admin.dob != credentials.dob:
        return schemas.LoginResponse(success=False, message="Invalid credentials")
    
    return schemas.LoginResponse(
        success=True,
        message="Login successful",
        user_id=admin.id,
        role="ADMIN",
        token=f"admin_{admin.id}_token"
    )

@app.post("/auth/driver/login", response_model=schemas.LoginResponse)
def driver_login(credentials: schemas.DriverLogin, db: Session = Depends(get_db)):
    """Driver/Dispatcher login using employee_id and password"""
    user = db.query(models.User).filter(
        models.User.employee_id == credentials.employee_id
    ).first()
    
    if not user:
        return schemas.LoginResponse(success=False, message="Invalid employee ID")
    
    # In production, use proper password hashing (bcrypt)
    if user.password != credentials.password:
        return schemas.LoginResponse(success=False, message="Invalid password")
    
    return schemas.LoginResponse(
        success=True,
        message="Login successful",
        user_id=user.id,
        role=user.role.value,
        token=f"driver_{user.id}_token"
    )

# ============ USER ENDPOINTS ============

@app.post("/users/", response_model=schemas.UserResponse)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Create new driver/dispatcher"""
    # Check if employee_id already exists (only if provided)
    if user.employee_id:
        existing = db.query(models.User).filter(models.User.employee_id == user.employee_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="Employee ID already exists")
    
    return crud.create_user(db=db, user=user)

@app.get("/users/", response_model=List[schemas.UserResponse])
def get_users(location_id: str = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all users, optionally filtered by location"""
    query = db.query(models.User)
    if location_id:
        query = query.filter(models.User.location_id == location_id)
    return query.offset(skip).limit(limit).all()

@app.get("/users/{user_id}", response_model=schemas.UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    """Get specific user details"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.patch("/users/{user_id}/availability")
def update_availability(user_id: int, is_available: bool, reason: str = None, db: Session = Depends(get_db)):
    """Update driver availability status"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_available = is_available
    if not is_available and reason:
        user.exemption_reason = reason
    
    db.commit()
    return {"message": "Availability updated", "is_available": is_available}

# ============ ROUTE ENDPOINTS ============

@app.post("/routes/", response_model=schemas.RouteResponse)
def create_route(route: schemas.RouteCreate, db: Session = Depends(get_db)):
    """Create new route with ML/AI analysis"""
    
    # Create route object for analysis
    temp_route = models.Route(**route.dict())
    
    # Run ML/AI satellite analysis
    ml_analysis = logic.analyze_route_from_satellite(temp_route)
    temp_route.terrain_difficulty = ml_analysis["terrain_difficulty"]
    temp_route.predicted_time_minutes = ml_analysis["predicted_time_minutes"]
    
    # Calculate grade
    grade, reason, route_score, route_credits = logic.calculate_route_grade(temp_route)
    
    # Create final route
    db_route = models.Route(
        **route.dict(),
        grade=grade,
        grade_reason=reason,
        route_score=route_score,
        route_credits=route_credits,
        terrain_difficulty=ml_analysis["terrain_difficulty"],
        predicted_time_minutes=ml_analysis["predicted_time_minutes"]
    )
    
    db.add(db_route)
    db.commit()
    db.refresh(db_route)
    return db_route

@app.get("/routes/", response_model=List[schemas.RouteResponse])
def get_routes(location_id: str = None, is_assigned: bool = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get routes, optionally filtered"""
    query = db.query(models.Route)
    if location_id:
        query = query.filter(models.Route.location_id == location_id)
    if is_assigned is not None:
        query = query.filter(models.Route.is_assigned == is_assigned)
    return query.offset(skip).limit(limit).all()

# ============ ASSIGNMENT ENDPOINTS ============

@app.get("/assignments/", response_model=List[schemas.AssignmentResponse])
def get_assignments(driver_id: int = None, status: str = None, db: Session = Depends(get_db)):
    """Get assignments, optionally filtered by driver or status"""
    query = db.query(models.Assignment)
    if driver_id:
        query = query.filter(models.Assignment.driver_id == driver_id)
    if status:
        query = query.filter(models.Assignment.status == status)
    return query.order_by(models.Assignment.assigned_date.desc()).all()

@app.post("/assignments/{assignment_id}/respond")
def respond_to_assignment(assignment_id: int, action: schemas.AssignmentAction, db: Session = Depends(get_db)):
    """Driver accepts or declines assignment"""
    assignment = db.query(models.Assignment).filter(models.Assignment.id == assignment_id).first()
    if not assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    
    if action.action == "accept":
        assignment.status = models.AssignmentStatus.ACCEPTED
        assignment.response_time = datetime.now()
        
        # Update route as assigned
        assignment.route.is_assigned = True
        
        # Award credits
        route_grade = assignment.route.grade
        policy = db.query(models.WeeklyPolicy).filter(
            models.WeeklyPolicy.location_id == assignment.driver.location_id
        ).first()
        
        if policy:
            if route_grade == models.RouteGrade.EASY:
                credits = policy.easy_route_credits
            elif route_grade == models.RouteGrade.MEDIUM:
                credits = policy.medium_route_credits
            else:
                credits = policy.hard_route_credits
            
            assignment.driver.credits += credits
            if assignment.reassignment_bonus > 0:
                assignment.driver.bonus_credits += assignment.reassignment_bonus
            
            # Log credits
            credit_log = models.CreditLog(
                driver_id=assignment.driver_id,
                amount=credits,
                reason=f"Accepted {route_grade.name} route",
                is_bonus=False
            )
            db.add(credit_log)
        
        # Create notification
        logic.create_notification(
            db, assignment.driver_id,
            "Route Accepted",
            f"You've accepted the {assignment.route.area} route. Good luck!",
            "route_accepted"
        )
        
        db.commit()
        return {"message": "Assignment accepted", "credits_earned": credits}
    
    elif action.action == "decline":
        assignment.status = models.AssignmentStatus.DECLINED
        assignment.response_time = datetime.now()
        assignment.decline_reason = action.decline_reason
        
        # Find available drivers for reassignment
        available_drivers = logic.find_available_drivers(
            db, 
            assignment.driver.location_id,
            exclude_driver_id=assignment.driver_id
        )
        
        if available_drivers:
            # Reassign to first available driver with bonus
            new_driver = available_drivers[0]
            bonus = 5  # Bonus credits for taking declined route
            
            new_assignment = models.Assignment(
                driver_id=new_driver.id,
                route_id=assignment.route_id,
                explanation=f"This route was reassigned to you. Thank you for your flexibility!",
                assignment_reason="Reassignment from declined route",
                original_driver_id=assignment.driver_id,
                reassignment_bonus=bonus,
                status=models.AssignmentStatus.PENDING
            )
            db.add(new_assignment)
            
            # Notify new driver
            logic.create_notification(
                db, new_driver.id,
                "New Route Assignment (Bonus!)",
                f"You've been assigned a route with +{bonus} bonus credits!",
                "route_assigned"
            )
            
            # Send email
            email_service.send_route_assignment_email(
                new_driver.email,
                new_driver.name,
                assignment.route.description,
                assignment.route.grade.name,
                new_assignment.explanation
            )
        
        db.commit()
        return {"message": "Assignment declined and reassigned"}
    
    else:
        raise HTTPException(status_code=400, detail="Invalid action")

# ============ NOTIFICATION ENDPOINTS ============

@app.get("/notifications/{user_id}", response_model=List[schemas.NotificationResponse])
def get_notifications(user_id: int, unread_only: bool = False, db: Session = Depends(get_db)):
    """Get user notifications"""
    query = db.query(models.Notification).filter(models.Notification.user_id == user_id)
    if unread_only:
        query = query.filter(models.Notification.is_read == False)
    return query.order_by(models.Notification.created_at.desc()).all()

@app.patch("/notifications/{notification_id}/read")
def mark_notification_read(notification_id: int, db: Session = Depends(get_db)):
    """Mark notification as read"""
    notification = db.query(models.Notification).filter(models.Notification.id == notification_id).first()
    if notification:
        notification.is_read = True
        db.commit()
    return {"message": "Notification marked as read"}

# ============ ADMIN ENDPOINTS ============

@app.get("/admin/dashboard/{location_id}", response_model=schemas.DashboardStats)
def get_admin_dashboard(location_id: str, db: Session = Depends(get_db)):
    """Get comprehensive admin dashboard stats"""
    drivers = db.query(models.User).filter(models.User.location_id == location_id).all()
    
    total_drivers = len(drivers)
    active_drivers = len([d for d in drivers if d.is_available])
    avg_fatigue = sum([d.fatigue_score for d in drivers]) / total_drivers if total_drivers > 0 else 0
    
    today = datetime.now().date()
    today_assignments = db.query(models.Assignment).filter(
        models.Assignment.assigned_date >= datetime.combine(today, datetime.min.time())
    ).all()
    
    total_routes_today = len(today_assignments)
    pending = len([a for a in today_assignments if a.status == models.AssignmentStatus.PENDING])
    completed = len([a for a in today_assignments if a.status == models.AssignmentStatus.COMPLETED])
    
    # Drivers needing attention
    attention_drivers = []
    for driver in drivers:
        if driver.fatigue_score > 70 or driver.health_status != models.HealthStatus.NORMAL:
            weekly_balance = logic.get_weekly_balance(driver, db)
            driver_assignments = [a for a in today_assignments if a.driver_id == driver.id]
            
            attention_drivers.append(schemas.DriverStats(
                driver_id=driver.id,
                driver_name=driver.name,
                fatigue=driver.fatigue_score,
                credits=driver.credits,
                bonus_credits=driver.bonus_credits,
                health_status=driver.health_status.value,
                weekly_balance={k.name: v for k, v in weekly_balance.items()},
                total_assignments=len([a for a in driver_assignments]),
                pending_assignments=len([a for a in driver_assignments if a.status == models.AssignmentStatus.PENDING])
            ))
    
    return schemas.DashboardStats(
        total_drivers=total_drivers,
        active_drivers=active_drivers,
        total_routes_today=total_routes_today,
        pending_assignments=pending,
        completed_today=completed,
        avg_fatigue=avg_fatigue,
        drivers_needing_attention=attention_drivers
    )

@app.post("/admin/policy/update")
def update_weekly_policy(policy: schemas.WeeklyPolicyUpdate, db: Session = Depends(get_db)):
    """Update weekly fairness policy for a location"""
    existing_policy = db.query(models.WeeklyPolicy).filter(
        models.WeeklyPolicy.location_id == policy.location_id
    ).first()
    
    if existing_policy:
        # Update existing
        for key, value in policy.dict(exclude_unset=True).items():
            if value is not None and key != "location_id":
                setattr(existing_policy, key, value)
        existing_policy.updated_at = datetime.now()
    else:
        # Create new
        new_policy = models.WeeklyPolicy(**policy.dict(exclude_unset=True))
        db.add(new_policy)
    
    db.commit()
    return {"message": "Policy updated successfully"}

@app.get("/admin/policy/{location_id}")
def get_weekly_policy(location_id: str, db: Session = Depends(get_db)):
    """Get current weekly policy for location"""
    policy = db.query(models.WeeklyPolicy).filter(
        models.WeeklyPolicy.location_id == location_id
    ).first()
    
    if not policy:
        # Return default policy
        return {
            "location_id": location_id,
            "easy_routes_target": 2,
            "medium_routes_target": 3,
            "hard_routes_target": 2,
            "easy_route_credits": 3,
            "medium_route_credits": 4,
            "hard_route_credits": 6,
            "max_consecutive_hard_routes": 2,
            "fatigue_threshold_for_restriction": 80.0
        }
    
    return policy

@app.get("/admin/reports/{location_id}")
def get_daily_reports(location_id: str, db: Session = Depends(get_db)):
    """Get history of daily formatted reports"""
    reports = db.query(models.DailyReport).filter(
        models.DailyReport.location_id == location_id
    ).order_by(models.DailyReport.report_date.desc()).all()
    return reports

# ============ DISPATCH ENGINE ============

def perform_dispatch(location_id: str, db: Session):
    """Refactored core dispatch logic for reuse"""
    # Get available drivers for this location
    drivers = db.query(models.User).filter(
        models.User.location_id == location_id,
        models.User.is_available == True
    ).all()
    
    if not drivers:
        return {"message": "No available drivers", "assignments_count": 0}
    
    # Get unassigned routes for this location
    available_routes = db.query(models.Route).filter(
        models.Route.location_id == location_id,
        models.Route.is_assigned == False
    ).all()
    
    if not available_routes:
        return {
            "message": "No unassigned routes found.",
            "assignments_count": 0
        }
    
    # Get policy
    policy = db.query(models.WeeklyPolicy).filter(
        models.WeeklyPolicy.location_id == location_id
    ).first()
    
    if not policy:
        policy = models.WeeklyPolicy(location_id=location_id)
        db.add(policy)
        db.commit()
    
    assignments_made = []
    
    # Use Intelligent AI-Powered Assignment System
    from . import intelligent_dispatch
    
    intelligent_assignments = intelligent_dispatch.intelligent_route_assignment(
        drivers=drivers,
        routes=available_routes,
        db=db,
        policy=policy
    )
    
    for driver, route, explanation, reason_code in intelligent_assignments:
        assignment = models.Assignment(
            driver_id=driver.id,
            route_id=route.id,
            explanation=explanation,
            assignment_reason=reason_code,
            status=models.AssignmentStatus.PENDING
        )
        db.add(assignment)
        assignments_made.append(assignment)
        route.is_assigned = True
        
        # Update fatigue
        if route.grade == models.RouteGrade.HARD:
            driver.fatigue_score = min(100, driver.fatigue_score + 15)
        elif route.grade == models.RouteGrade.MEDIUM:
            driver.fatigue_score = min(100, driver.fatigue_score + 8)
        else:
            driver.fatigue_score = max(0, driver.fatigue_score - 5)
        
        # Update health
        if driver.fatigue_score >= 80:
            driver.health_status = models.HealthStatus.RESTRICTED
        elif driver.fatigue_score >= 60:
            driver.health_status = models.HealthStatus.CAUTION
        else:
            driver.health_status = models.HealthStatus.NORMAL
        
        # Create notification
        logic.create_notification(
            db, driver.id,
            f"New {route.grade.name} Route Assigned",
            explanation,
            "route_assigned"
        )
        
        # Email
        try:
            email_service.send_route_assignment_email(
                driver.email, driver.name, route.description, route.grade.name, explanation
            )
        except: pass
        
    db.commit()
    
    # Generate Report
    try:
        pdf_path = pdf_service.generate_daily_report(
            assignments=assignments_made,
            location_id=location_id,
            date_str=datetime.now().strftime("%Y-%m-%d")
        )
        report = models.DailyReport(
            report_date=datetime.now(),
            location_id=location_id,
            pdf_path=pdf_path,
            assignments_count=len(assignments_made)
        )
        db.add(report)
        db.commit()
    except Exception as e:
        print(f"Error report: {e}")

    return {"message": "Success", "assignments_count": len(assignments_made)}

@app.post("/dispatch/run")
def run_daily_dispatch(location_id: str, db: Session = Depends(get_db)):
    """Run the AI-powered fair dispatch algorithm manually"""
    return perform_dispatch(location_id, db)

async def auto_dispatch_scheduler():
    """Background task to run auto-dispatches based on time rule"""
    while True:
        try:
            db = database.SessionLocal()
            now = datetime.now()
            current_time = now.strftime("%H:%M")
            
            # Find policies with auto-dispatch enabled
            policies = db.query(models.WeeklyPolicy).filter(
                models.WeeklyPolicy.auto_dispatch_enabled == True,
                models.WeeklyPolicy.auto_dispatch_time == current_time
            ).all()
            
            for policy in policies:
                print(f"[{datetime.now()}] Triggering Auto-Dispatch for {policy.location_id}")
                perform_dispatch(policy.location_id, db)
                
            db.close()
        except Exception as e:
            print(f"Scheduler Error: {e}")
            
        # Wait 60 seconds before next check
        await asyncio.sleep(60)

@app.on_event("startup")
async def startup_event():
    print("Starting Auto-Dispatch Scheduler...")
    asyncio.create_task(auto_dispatch_scheduler())

# ============ DEMO DATA ENDPOINT ============

@app.post("/demo/populate")
def populate_demo_data(location_id: str = "LOC001", db: Session = Depends(get_db)):
    """Populate demo data for testing"""
    
    # Create admin
    admin = models.Admin(
        location_id=location_id,
        year="2024",
        dob="01011990",
        name="Admin User",
        email="admin@fairdispatch.com"
    )
    if not db.query(models.Admin).filter(models.Admin.location_id == location_id).first():
        db.add(admin)
    
    # Create drivers
    drivers_data = [
        {"name": "Alex Driver", "email": "alex@fds.com", "employee_id": "EMP001", "password": "pass123", "fatigue": 30, "health": models.HealthStatus.NORMAL},
        {"name": "Sam Tired", "email": "sam@fds.com", "employee_id": "EMP002", "password": "pass123", "fatigue": 85, "health": models.HealthStatus.RESTRICTED},
        {"name": "Jamie Fresh", "email": "jamie@fds.com", "employee_id": "EMP003", "password": "pass123", "fatigue": 10, "health": models.HealthStatus.NORMAL},
        {"name": "Taylor Swift", "email": "taylor@fds.com", "employee_id": "EMP004", "password": "pass123", "fatigue": 45, "health": models.HealthStatus.CAUTION},
    ]
    
    for d_data in drivers_data:
        if not db.query(models.User).filter(models.User.employee_id == d_data["employee_id"]).first():
            driver = models.User(
                name=d_data["name"],
                email=d_data["email"],
                employee_id=d_data["employee_id"],
                password=d_data["password"],
                role=models.UserRole.DRIVER,
                location_id=location_id,
                fatigue_score=d_data["fatigue"],
                health_status=d_data["health"],
                credits=15,
                is_available=True
            )
            db.add(driver)
    
    # Create routes with realistic GPS coordinates (example: around a city)
    base_lat, base_lng = 13.0827, 80.2707  # Chennai, India (or use user's location)
    
    routes_data = [
        {"desc": "T Nagar Residential Complex", "packages": 45, "weight": 65.0, "elevator": True, "traffic": 0.3, "density": 0.4, "walk": 1.5, "stairs": 10, "parking": 0.2},
        {"desc": "Anna Nagar Apartments", "packages": 120, "weight": 180.0, "elevator": False, "traffic": 0.8, "density": 0.9, "walk": 4.5, "stairs": 60, "parking": 0.9},
        {"desc": "Adyar Beach Road Villas", "packages": 30, "weight": 40.0, "elevator": True, "traffic": 0.2, "density": 0.2, "walk": 0.8, "stairs": 5, "parking": 0.1},
        {"desc": "Velachery High-Rise", "packages": 95, "weight": 140.0, "elevator": True, "traffic": 0.7, "density": 0.8, "walk": 3.2, "stairs": 15, "parking": 0.6},
        {"desc": "Mylapore Temple Street", "packages": 150, "weight": 220.0, "elevator": False, "traffic": 0.9, "density": 1.0, "walk": 6.0, "stairs": 80, "parking": 1.0},
        {"desc": "OMR Tech Park", "packages": 60, "weight": 85.0, "elevator": True, "traffic": 0.5, "density": 0.5, "walk": 2.0, "stairs": 0, "parking": 0.3},
    ]
    
    for i, r_data in enumerate(routes_data):
        # Generate GPS coordinates around base location
        lat_offset = random.uniform(-0.05, 0.05)
        lng_offset = random.uniform(-0.05, 0.05)
        
        route_create = schemas.RouteCreate(
            description=r_data["desc"],
            area=f"Zone {chr(65+i)}",
            location_id=location_id,
            start_lat=base_lat,
            start_lng=base_lng,
            end_lat=base_lat + lat_offset,
            end_lng=base_lng + lng_offset,
            package_count=r_data["packages"],
            weight_kg=r_data["weight"],
            has_elevator=r_data["elevator"],
            traffic_level=r_data["traffic"],
            apartment_density=r_data["density"],
            walking_distance_km=r_data["walk"],
            stairs_count=r_data["stairs"],
            parking_difficulty=r_data["parking"]
        )
        
        # Check if route already exists
        existing = db.query(models.Route).filter(
            models.Route.description == r_data["desc"],
            models.Route.location_id == location_id
        ).first()
        
        if not existing:
            # Create route with ML analysis
            temp_route = models.Route(**route_create.dict())
            ml_analysis = logic.analyze_route_from_satellite(temp_route)
            grade, reason, route_score, route_credits = logic.calculate_route_grade(temp_route)
            
            db_route = models.Route(
                **route_create.dict(),
                grade=grade,
                grade_reason=reason,
                route_score=route_score,
                route_credits=route_credits,
                terrain_difficulty=ml_analysis["terrain_difficulty"],
                predicted_time_minutes=ml_analysis["predicted_time_minutes"]
            )
            db.add(db_route)
    
    # Create default policy
    if not db.query(models.WeeklyPolicy).filter(models.WeeklyPolicy.location_id == location_id).first():
        policy = models.WeeklyPolicy(location_id=location_id)
        db.add(policy)
    
    db.commit()
    return {"message": "Demo data populated successfully", "location_id": location_id}

@app.get("/")
def root():
    return {
        "message": "FairDispatch AI API",
        "version": "2.0.0",
        "status": "running",
        "features": [
            "Dual Authentication (Admin & Driver)",
            "ML/AI Route Analysis",
            "Fair Dispatch Algorithm",
            "Email Notifications",
            "Real-time Dashboard",
            "Route Accept/Decline",
            "Automatic Reassignment",
            "Credit & Bonus System"
        ]
    }
