"""
Quick script to check database state and create test assignments
"""
from sqlalchemy import create_engine, text
from backend.app.database import DATABASE_URL
from backend.app import models
from sqlalchemy.orm import sessionmaker

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
db = SessionLocal()

print("=== DATABASE STATUS ===\n")

# Check users
users = db.query(models.User).filter(models.User.role == models.UserRole.DRIVER).all()
print(f"Drivers: {len(users)}")
for u in users[:3]:
    print(f"  - {u.name} ({u.employee_id}): Fatigue={u.fatigue_score}, Health={u.health_status.value}")

# Check routes
routes = db.query(models.Route).all()
print(f"\nRoutes: {len(routes)}")
for r in routes[:3]:
    print(f"  - {r.area}: Grade={r.grade.value if r.grade else 'None'}, Assigned={r.is_assigned}")

# Check assignments
assignments = db.query(models.Assignment).all()
print(f"\nAssignments: {len(assignments)}")
for a in assignments[:3]:
    driver = db.query(models.User).filter(models.User.id == a.driver_id).first()
    route = db.query(models.Route).filter(models.Route.id == a.route_id).first()
    print(f"  - {driver.name if driver else 'Unknown'} → {route.area if route else 'Unknown'}: {a.status.value}")

print("\n=== CREATING TEST ASSIGNMENT ===\n")

# Create a simple test assignment if we have users and routes
if users and routes:
    # Find an unassigned route
    unassigned_route = db.query(models.Route).filter(models.Route.is_assigned == False).first()
    
    if unassigned_route and users:
        test_assignment = models.Assignment(
            driver_id=users[0].id,
            route_id=unassigned_route.id,
            explanation=f"Test assignment for {users[0].name}. Route: {unassigned_route.area}",
            assignment_reason="manual_test",
            status=models.AssignmentStatus.PENDING
        )
        db.add(test_assignment)
        unassigned_route.is_assigned = True
        db.commit()
        print(f"✓ Created test assignment: {users[0].name} → {unassigned_route.area}")
    else:
        print("✗ No unassigned routes available")
else:
    print("✗ No users or routes in database")

db.close()
