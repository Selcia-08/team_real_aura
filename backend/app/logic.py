from .models import Route, User, RouteGrade, HealthStatus, Assignment, AssignmentStatus, Notification, WeeklyPolicy
from sqlalchemy.orm import Session
import random
from datetime import datetime, timedelta
import math

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates in km"""
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

def analyze_route_from_satellite(route: Route) -> dict:
    """
    Simulate ML/AI analysis of route based on satellite imagery
    In production, this would call a real ML model
    """
    # Simulate terrain analysis
    distance = calculate_distance(route.start_lat, route.start_lng, route.end_lat, route.end_lng)
    
    # Mock terrain difficulty (0.0 to 1.0)
    # In production: analyze satellite images for hills, construction, etc.
    terrain_difficulty = random.uniform(0.2, 0.9)
    
    # Predict delivery time based on multiple factors
    base_time = distance * 10  # 10 min per km base
    traffic_penalty = route.traffic_level * 20
    terrain_penalty = terrain_difficulty * 15
    stairs_penalty = route.stairs_count * 2
    
    predicted_time = int(base_time + traffic_penalty + terrain_penalty + stairs_penalty)
    
    return {
        "terrain_difficulty": terrain_difficulty,
        "predicted_time_minutes": predicted_time,
        "distance_km": distance
    }

def calculate_route_grade(route: Route) -> tuple[RouteGrade, str, int, int]:
    """
    Calculate route difficulty grade using comprehensive mathematical formula
    
    Route Score = P + W + D + T + SD + AD
    
    Where:
    - P = Package Count
    - W = Weight Score (categorized by weight ranges)
    - D = Distance Score (distance × 3)
    - T = Time Score (based on estimated delivery time)
    - SD = Stop Difficulty Score (COD + Apartment stops)
    - AD = Apartment Heavy Package Penalty
    
    Returns: (grade, reason, score, credits)
    """
    score = 0
    reasons = []
    breakdown = []
    
    # 1. Package Count (P)
    P = route.package_count
    score += P
    breakdown.append(f"Packages: {P}")
    
    # 2. Weight Score (W)
    # Categorize packages by weight and calculate points
    # Assuming average weight per package for distribution
    avg_weight_per_package = route.weight_kg / max(route.package_count, 1)
    
    W = 0
    if avg_weight_per_package <= 5:
        W = route.package_count * 1
        reasons.append("light packages (≤5kg)")
    elif avg_weight_per_package <= 10:
        W = route.package_count * 2
        reasons.append("moderate packages (5-10kg)")
    elif avg_weight_per_package <= 20:
        W = route.package_count * 4
        reasons.append("heavy packages (10-20kg)")
    else:
        W = route.package_count * 6
        reasons.append("very heavy packages (>20kg)")
    
    score += W
    breakdown.append(f"Weight: {W}")
    
    # 3. Distance Score (D)
    distance_km = calculate_distance(route.start_lat, route.start_lng, route.end_lat, route.end_lng)
    D = int(distance_km * 3)
    score += D
    breakdown.append(f"Distance: {D} ({distance_km:.1f}km)")
    
    # 4. Time Score (T)
    estimated_time_hours = (route.predicted_time_minutes or 120) / 60
    
    if estimated_time_hours <= 4:
        T = 50
    elif estimated_time_hours <= 6:
        T = 100
        reasons.append("moderate delivery time (4-6h)")
    elif estimated_time_hours <= 8:
        T = 160
        reasons.append("long delivery time (6-8h)")
    else:
        T = 220
        reasons.append("very long delivery time (>8h)")
    
    score += T
    breakdown.append(f"Time: {T}")
    
    # 5. Stop Difficulty Score (SD)
    # Estimate COD stops (assume 30% of packages) and apartment stops (based on density)
    cod_stops = int(route.package_count * 0.3)  # 30% COD assumption
    apartment_stops = int(route.package_count * route.apartment_density)
    
    SD = (cod_stops * 3) + (apartment_stops * 5)
    score += SD
    breakdown.append(f"Stops: {SD}")
    
    if apartment_stops > route.package_count * 0.5:
        reasons.append(f"many apartment deliveries ({apartment_stops})")
    
    # 6. Apartment Heavy Package Penalty (AD)
    # Apply penalty for heavy packages in apartments
    AD = 0
    if not route.has_elevator and route.apartment_density > 0.5:
        if avg_weight_per_package > 20:
            AD = apartment_stops * 6
            reasons.append("heavy packages in apartments without elevator")
        elif avg_weight_per_package > 10:
            AD = apartment_stops * 3
            reasons.append("moderate packages in apartments without elevator")
    
    score += AD
    if AD > 0:
        breakdown.append(f"Apartment Penalty: {AD}")
    
    # Additional factors
    if route.stairs_count > 50:
        score += 20
        reasons.append(f"excessive stairs ({route.stairs_count})")
    
    if route.parking_difficulty > 0.7:
        score += int(route.parking_difficulty * 30)
        reasons.append("difficult parking")
    
    # Determine grade based on score ranges
    if score <= 650:
        grade = RouteGrade.EASY
        grade_desc = "Easy"
        credits = 1
    elif score <= 1200:
        grade = RouteGrade.MEDIUM
        grade_desc = "Medium"
        credits = 2
    else:
        grade = RouteGrade.HARD
        grade_desc = "Hard"
        credits = 3
    
    # Build comprehensive reason text
    score_breakdown = " + ".join(breakdown)
    reason_text = (
        f"Route Score: {score} ({grade_desc}, {credits} credits). "
        f"Breakdown: {score_breakdown}. "
        f"Key factors: {', '.join(reasons[:3]) if reasons else 'standard delivery'}"
    )
    
    return grade, reason_text, score, credits


def get_weekly_balance(driver: User, db: Session):
    """Calculate counts of Easy, Medium, Hard routes in last 7 days"""
    one_week_ago = datetime.now() - timedelta(days=7)
    recent_assignments = db.query(Assignment).filter(
        Assignment.driver_id == driver.id,
        Assignment.assigned_date >= one_week_ago,
        Assignment.status.in_([AssignmentStatus.ACCEPTED, AssignmentStatus.COMPLETED])
    ).all()
    
    counts = {RouteGrade.EASY: 0, RouteGrade.MEDIUM: 0, RouteGrade.HARD: 0}
    for a in recent_assignments:
        if a.route:
            counts[a.route.grade] += 1
            
    return counts

def generate_explanation(driver: User, route_grade: RouteGrade, reason_code: str, weekly_balance: dict):
    """Generate human-friendly explanation for route assignment"""
    
    intros = [
        f"Hi {driver.name.split()[0]},",
        f"Hello {driver.name.split()[0]},",
        f"Good morning {driver.name.split()[0]},"
    ]
    
    intro = random.choice(intros)
    
    if reason_code == "health_recovery":
        return f"{intro} we've assigned you a lighter route today to support your health and recovery. Your well-being is our priority."
    
    elif reason_code == "fatigue_management":
        return f"{intro} you've been working hard lately. This easier route will help you recover while maintaining your excellent performance."
    
    elif reason_code == "weekly_balance_hard":
        hard_count = weekly_balance.get(RouteGrade.HARD, 0)
        return f"{intro} you've completed {hard_count} hard routes this week. This challenging route helps maintain fair distribution across the team."
    
    elif reason_code == "weekly_balance_easy":
        hard_count = weekly_balance.get(RouteGrade.HARD, 0)
        return f"{intro} you've handled {hard_count} difficult routes recently. This lighter assignment balances your weekly workload."
    
    elif reason_code == "credit_usage":
        return f"{intro} as requested, we've used your credits to assign a lighter route today. Enjoy the easier drive!"
    
    elif reason_code == "new_driver":
        return f"{intro} as you're building experience, we've selected a route that matches your current skill level."
    
    elif reason_code == "performance_reward":
        return f"{intro} your excellent performance has earned you this preferred route. Keep up the great work!"
    
    elif reason_code == "team_fairness":
        return f"{intro} this assignment ensures fair distribution across the team while considering your recent workload."
    
    return f"{intro} this route has been carefully selected based on current conditions and fair distribution principles."

def create_notification(db: Session, user_id: int, title: str, message: str, notification_type: str):
    """Create in-app notification for user"""
    notification = Notification(
        user_id=user_id,
        title=title,
        message=message,
        notification_type=notification_type
    )
    db.add(notification)
    db.commit()
    return notification

def find_available_drivers(db: Session, location_id: str, exclude_driver_id: int = None):
    """Find available drivers for reassignment"""
    query = db.query(User).filter(
        User.location_id == location_id,
        User.is_available == True,
        User.health_status != HealthStatus.RESTRICTED
    )
    
    if exclude_driver_id:
        query = query.filter(User.id != exclude_driver_id)
    
    return query.all()
