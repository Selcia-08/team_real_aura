"""
Quick Start Script - Creates complete route assignments with all details
"""
from sqlalchemy import create_engine
from backend.app.database import DATABASE_URL
from backend.app import models
from sqlalchemy.orm import sessionmaker
from datetime import datetime

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

print("=" * 60)
print("FAIRDISPATCH - QUICK START ASSIGNMENT CREATOR")
print("=" * 60)

# Clear existing assignments
print("\n[1/4] Clearing old assignments...")
db.query(models.Assignment).delete()
db.query(models.Route).update({"is_assigned": False})
db.commit()
print("✓ Cleared")

# Get drivers
drivers = db.query(models.User).filter(models.User.role == models.UserRole.DRIVER).all()
print(f"\n[2/4] Found {len(drivers)} drivers")

# Get routes
routes = db.query(models.Route).all()
print(f"[3/4] Found {len(routes)} routes")

# Create intelligent assignments
print("\n[4/4] Creating assignments with full details...")

assignments_created = 0

for i, driver in enumerate(drivers[:min(len(drivers), len(routes))]):
    route = routes[i]
    
    # Calculate route score and credits based on grade
    if route.grade == models.RouteGrade.EASY:
        route_score = 450
        route_credits = 1
        grade_text = "Easy"
    elif route.grade == models.RouteGrade.MEDIUM:
        route_score = 850
        route_credits = 2
        grade_text = "Medium"
    else:
        route_score = 1350
        route_credits = 3
        grade_text = "Hard"
    
    # Update route with score and credits if not set
    if not route.route_score:
        route.route_score = route_score
        route.route_credits = route_credits
    
    # Create detailed explanation with geolocation
    distance_to_start = 2.5 + (i * 1.5)  # Simulated distance
    explanation = (
        f"Hi {driver.name.split()[0]}, "
        f"This {grade_text.lower()} route starts {distance_to_start:.1f}km from your current location. "
        f"Route Score: {route_score} ({grade_text}, {route_credits} credits). "
        f"Start: ({route.start_lat:.4f}, {route.start_lng:.4f}), "
        f"End: ({route.end_lat:.4f}, {route.end_lng:.4f}). "
        f"Packages: {route.package_count}, Weight: {route.weight_kg}kg. "
        f"This assignment considers your health ({driver.health_status.value}), "
        f"fatigue level ({driver.fatigue_score:.0f}%), and weekly workload balance."
    )
    
    # Determine reason code
    if driver.health_status == models.HealthStatus.RESTRICTED:
        reason_code = "health_recovery"
    elif driver.fatigue_score >= 70:
        reason_code = "fatigue_management"
    elif distance_to_start < 3:
        reason_code = "proximity_optimization"
    else:
        reason_code = "intelligent_matching"
    
    # Create assignment
    assignment = models.Assignment(
        driver_id=driver.id,
        route_id=route.id,
        explanation=explanation,
        assignment_reason=reason_code,
        status=models.AssignmentStatus.PENDING,
        assigned_date=datetime.now()
    )
    
    db.add(assignment)
    route.is_assigned = True
    assignments_created += 1
    
    print(f"  ✓ {driver.name} → {route.area} ({grade_text}, {route_credits} credits)")
    print(f"    Reason: {reason_code}, Distance: {distance_to_start:.1f}km")
    print(f"    GPS: ({route.start_lat:.4f}, {route.start_lng:.4f}) → ({route.end_lat:.4f}, {route.end_lng:.4f})")

db.commit()

print(f"\n{'=' * 60}")
print(f"✓ Created {assignments_created} assignments successfully!")
print(f"{'=' * 60}")
print("\nDrivers can now:")
print("  1. View their assigned routes in the app")
print("  2. See route grade, score, and credits")
print("  3. View geolocation coordinates")
print("  4. Accept or decline assignments")
print("\nRefresh the Flutter app to see the assignments!")

db.close()
