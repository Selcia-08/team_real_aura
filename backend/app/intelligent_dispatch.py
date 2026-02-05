"""
Intelligent AI-Powered Route Assignment System
Considers geolocation, driver proximity, fairness, and human-like decision making
"""
from .models import Route, User, RouteGrade, HealthStatus, Assignment
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import math
import random
from typing import List, Tuple, Dict

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates in km using Haversine formula"""
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

def get_driver_current_location(driver: User) -> Tuple[float, float]:
    """
    Get driver's current location
    In production: This would come from GPS tracking
    For now: Use their last delivery endpoint or home base
    """
    # Simulate driver locations around the city
    # In production, this would be real-time GPS data
    base_lat = 13.0827  # Chennai coordinates
    base_lng = 80.2707
    
    # Add some variation based on driver ID (simulating different locations)
    offset_lat = (driver.id * 123 % 100) / 10000.0
    offset_lng = (driver.id * 456 % 100) / 10000.0
    
    return (base_lat + offset_lat, base_lng + offset_lng)

def calculate_driver_route_compatibility(driver: User, route: Route, db: Session) -> Dict:
    """
    Calculate how well a driver matches a route
    Returns a compatibility score (0-100) and detailed reasoning
    """
    score = 50  # Base score
    reasons = []
    penalties = []
    bonuses = []
    
    # 1. GEOLOCATION PROXIMITY (Most Important - 30 points)
    driver_lat, driver_lng = get_driver_current_location(driver)
    distance_to_start = calculate_distance(driver_lat, driver_lng, route.start_lat, route.start_lng)
    
    if distance_to_start < 2:  # Within 2km
        proximity_bonus = 30
        bonuses.append(f"Very close to route start ({distance_to_start:.1f}km)")
    elif distance_to_start < 5:  # Within 5km
        proximity_bonus = 20
        bonuses.append(f"Close to route start ({distance_to_start:.1f}km)")
    elif distance_to_start < 10:  # Within 10km
        proximity_bonus = 10
        bonuses.append(f"Moderate distance to start ({distance_to_start:.1f}km)")
    else:
        proximity_bonus = 0
        penalties.append(f"Far from route start ({distance_to_start:.1f}km)")
    
    score += proximity_bonus
    
    # 2. HEALTH STATUS (20 points)
    if driver.health_status == HealthStatus.RESTRICTED:
        if route.grade == RouteGrade.EASY:
            score += 20
            bonuses.append("Health status matches easy route")
        elif route.grade == RouteGrade.MEDIUM:
            score -= 10
            penalties.append("Health status not ideal for medium route")
        else:
            score -= 30
            penalties.append("Health status incompatible with hard route")
    elif driver.health_status == HealthStatus.CAUTION:
        if route.grade == RouteGrade.HARD:
            score -= 15
            penalties.append("Caution status, hard route not recommended")
        elif route.grade == RouteGrade.EASY:
            score += 10
            bonuses.append("Caution status, easy route is good")
    else:  # NORMAL
        score += 10
        bonuses.append("Normal health status")
    
    # 3. FATIGUE LEVEL (15 points)
    if driver.fatigue_score < 30:
        if route.grade == RouteGrade.HARD:
            score += 15
            bonuses.append("Low fatigue, can handle hard route")
        else:
            score += 5
    elif driver.fatigue_score < 60:
        if route.grade == RouteGrade.MEDIUM:
            score += 10
            bonuses.append("Moderate fatigue, medium route is ideal")
        elif route.grade == RouteGrade.HARD:
            score -= 5
    else:  # High fatigue
        if route.grade == RouteGrade.EASY:
            score += 15
            bonuses.append("High fatigue, easy route is best")
        elif route.grade == RouteGrade.MEDIUM:
            score -= 10
            penalties.append("High fatigue, medium route may be challenging")
        else:
            score -= 25
            penalties.append("High fatigue, hard route not recommended")
    
    # 4. WEEKLY BALANCE (15 points)
    from .logic import get_weekly_balance
    weekly_balance = get_weekly_balance(driver, db)
    
    # Check if driver needs this type of route
    if route.grade == RouteGrade.HARD:
        if weekly_balance[RouteGrade.HARD] < 2:
            score += 15
            bonuses.append("Needs more hard routes for weekly balance")
        elif weekly_balance[RouteGrade.HARD] >= 3:
            score -= 10
            penalties.append("Already has enough hard routes this week")
    elif route.grade == RouteGrade.MEDIUM:
        if weekly_balance[RouteGrade.MEDIUM] < 3:
            score += 10
            bonuses.append("Needs more medium routes for balance")
    else:  # EASY
        if weekly_balance[RouteGrade.EASY] < 2:
            score += 10
            bonuses.append("Needs more easy routes for balance")
    
    # 5. EXPERIENCE & SKILL (10 points)
    # Simulate experience based on total completed routes
    total_routes = sum(weekly_balance.values())
    if total_routes > 15:  # Experienced driver
        if route.grade == RouteGrade.HARD:
            score += 10
            bonuses.append("Experienced driver, can handle complex routes")
    elif total_routes < 5:  # New driver
        if route.grade == RouteGrade.EASY:
            score += 10
            bonuses.append("New driver, easy route for skill building")
        elif route.grade == RouteGrade.HARD:
            score -= 15
            penalties.append("New driver, hard route not recommended")
    
    # 6. ROUTE CHARACTERISTICS MATCH (10 points)
    # Consider if route characteristics match driver's strengths
    if not route.has_elevator and route.stairs_count > 50:
        if driver.fatigue_score < 40:
            score += 5
            bonuses.append("Low fatigue, can handle stairs")
        else:
            score -= 10
            penalties.append("High stairs count with elevated fatigue")
    
    if route.parking_difficulty > 0.7:
        # Experienced drivers handle difficult parking better
        if total_routes > 10:
            score += 5
            bonuses.append("Experienced with difficult parking")
        else:
            score -= 5
            penalties.append("Difficult parking area")
    
    # 7. TIME OF DAY CONSIDERATION (Bonus)
    current_hour = datetime.now().hour
    if 6 <= current_hour <= 10:  # Morning rush
        if route.traffic_level < 0.5:
            score += 5
            bonuses.append("Low traffic route during morning")
    elif 17 <= current_hour <= 20:  # Evening rush
        if route.traffic_level < 0.5:
            score += 5
            bonuses.append("Low traffic route during evening")
    
    # Ensure score stays within 0-100
    score = max(0, min(100, score))
    
    return {
        "score": score,
        "distance_to_start": distance_to_start,
        "bonuses": bonuses,
        "penalties": penalties,
        "reasons": bonuses + penalties
    }

def intelligent_route_assignment(
    drivers: List[User],
    routes: List[Route],
    db: Session,
    policy
) -> List[Tuple[User, Route, str, str]]:
    """
    Intelligent AI-powered route assignment
    Returns: List of (driver, route, explanation, reason_code) tuples
    
    This algorithm thinks like a human dispatcher:
    1. Considers driver location and proximity
    2. Respects health and fatigue
    3. Balances workload fairly
    4. Matches skills to route difficulty
    5. Optimizes for efficiency and driver wellbeing
    """
    assignments = []
    available_drivers = drivers.copy()
    available_routes = routes.copy()
    
    # Sort routes by urgency (hard routes first, then by distance)
    available_routes.sort(key=lambda r: (
        -r.grade.value,  # Hard routes first
        -r.package_count  # More packages = higher priority
    ))
    
    iteration = 0
    max_iterations = len(drivers) * 2  # Prevent infinite loops
    
    while available_routes and available_drivers and iteration < max_iterations:
        iteration += 1
        best_match = None
        best_score = -1
        best_compatibility = None
        
        # For each route, find the best driver
        for route in available_routes[:3]:  # Consider top 3 routes
            for driver in available_drivers:
                # Calculate compatibility
                compatibility = calculate_driver_route_compatibility(driver, route, db)
                
                # Add randomness for human-like decision making (±5 points)
                adjusted_score = compatibility["score"] + random.uniform(-5, 5)
                
                if adjusted_score > best_score:
                    best_score = adjusted_score
                    best_match = (driver, route)
                    best_compatibility = compatibility
        
        # If we found a good match (score > 40), make the assignment
        if best_match and best_score > 40:
            driver, route = best_match
            
            # Generate human-like explanation
            explanation = generate_intelligent_explanation(
                driver, route, best_compatibility
            )
            
            # Determine reason code
            reason_code = determine_reason_code(driver, route, best_compatibility)
            
            assignments.append((driver, route, explanation, reason_code))
            
            # Remove assigned driver and route
            available_drivers.remove(driver)
            available_routes.remove(route)
        else:
            # No good match found, break to avoid poor assignments
            break
    
    return assignments

def generate_intelligent_explanation(driver: User, route: Route, compatibility: Dict) -> str:
    """Generate human-like explanation for route assignment"""
    first_name = driver.name.split()[0]
    
    # Start with a friendly greeting
    greetings = [
        f"Hi {first_name},",
        f"Hello {first_name},",
        f"Good morning {first_name}," if datetime.now().hour < 12 else f"Good afternoon {first_name},",
    ]
    greeting = random.choice(greetings)
    
    # Build explanation based on top reasons
    top_bonuses = compatibility["bonuses"][:2]
    distance = compatibility["distance_to_start"]
    
    if distance < 2:
        location_note = f"This route starts just {distance:.1f}km from your current location, minimizing your commute time."
    elif distance < 5:
        location_note = f"You're {distance:.1f}km from the route start, making this a convenient assignment."
    else:
        location_note = f"While the route is {distance:.1f}km away, it's the best match for your current status."
    
    # Add personalized notes
    if top_bonuses:
        reason_text = " ".join(top_bonuses[:2])
        explanation = f"{greeting} {location_note} {reason_text}. This assignment considers your health, fatigue level, and weekly workload balance to ensure fairness."
    else:
        explanation = f"{greeting} {location_note} This route has been carefully selected based on current conditions and fair distribution principles."
    
    return explanation

def determine_reason_code(driver: User, route: Route, compatibility: Dict) -> str:
    """Determine the primary reason code for the assignment"""
    if driver.health_status == HealthStatus.RESTRICTED:
        return "health_recovery"
    elif driver.fatigue_score >= 70:
        return "fatigue_management"
    elif compatibility["distance_to_start"] < 2:
        return "proximity_optimization"
    elif "weekly balance" in " ".join(compatibility["bonuses"]).lower():
        return "weekly_balance"
    else:
        return "intelligent_matching"
