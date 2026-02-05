# Route Grading & Credit Calculation System

## Overview
The FairDispatch AI system uses a comprehensive mathematical formula to calculate route difficulty scores, assign grades (Easy, Medium, Hard), and determine credit values for fair workload distribution among drivers.

## Mathematical Formula

### Route Score Calculation
```
Route Score = P + W + D + T + SD + AD
```

Where:
- **P** = Package Count
- **W** = Weight Score
- **D** = Distance Score
- **T** = Time Score
- **SD** = Stop Difficulty Score
- **AD** = Apartment Heavy Package Penalty

## Detailed Component Breakdown

### 1. Package Count (P)
```
P = Total number of packages
```
- Direct count of all packages in the route
- Example: 25 packages = 25 points

### 2. Weight Score (W)
Packages are categorized by average weight and assigned points:

| Package Weight | Points per Package |
|---------------|-------------------|
| ≤ 5 kg        | 1                 |
| 5–10 kg       | 2                 |
| 10–20 kg      | 4                 |
| > 20 kg       | 6                 |

```
W = Σ(packages in each weight range × points)
```

**Example:**
- 25 packages, total weight 125kg
- Average weight per package: 125/25 = 5kg
- Weight Score: 25 × 2 = 50 points

### 3. Distance Score (D)
```
D = Total distance (km) × 3
```

**Example:**
- Distance: 15.5 km
- Distance Score: 15.5 × 3 = 46.5 ≈ 47 points

### 4. Time Score (T)
Based on estimated delivery time:

| Estimated Time | Points |
|---------------|--------|
| ≤ 4 hours     | 50     |
| 4–6 hours     | 100    |
| 6–8 hours     | 160    |
| > 8 hours     | 220    |

**Example:**
- Predicted time: 5.5 hours
- Time Score: 100 points

### 5. Stop Difficulty Score (SD)
```
SD = (COD stops × 3) + (Apartment stops × 5)
```

**Assumptions:**
- COD stops = 30% of total packages
- Apartment stops = Package count × Apartment density

**Example:**
- 25 packages, 60% apartment density
- COD stops: 25 × 0.3 = 7.5 ≈ 8
- Apartment stops: 25 × 0.6 = 15
- SD = (8 × 3) + (15 × 5) = 24 + 75 = 99 points

### 6. Apartment Heavy Package Penalty (AD)
Applied only for heavy packages delivered to apartments **without elevators**:

| Condition | Extra Points per Apartment Stop |
|-----------|-------------------------------|
| 10–20 kg in apartment (no elevator) | +3 |
| > 20 kg in apartment (no elevator) | +6 |

```
AD = Σ(heavy apartment packages × penalty)
```

**Example:**
- 15 apartment stops, no elevator, avg weight 12kg
- AD = 15 × 3 = 45 points

## Additional Factors

### Stairs Penalty
- If stairs > 50: +20 points

### Parking Difficulty
- If parking difficulty > 0.7: +(parking_difficulty × 30) points

## Grade Assignment

Based on the final Route Score:

| Route Score Range | Grade  | Credits |
|------------------|--------|---------|
| ≤ 650            | Easy   | 1       |
| 651 – 1200       | Medium | 2       |
| > 1200           | Hard   | 3       |

## Complete Example Calculation

### Route Details:
- **Packages**: 25
- **Total Weight**: 125 kg (avg 5kg/package)
- **Distance**: 15.5 km
- **Predicted Time**: 5.5 hours
- **Apartment Density**: 60%
- **Has Elevator**: No
- **Stairs**: 60
- **Parking Difficulty**: 0.8

### Calculation:
1. **P** (Packages): 25
2. **W** (Weight): 25 × 2 = 50
3. **D** (Distance): 15.5 × 3 = 47
4. **T** (Time): 100 (4-6 hours)
5. **SD** (Stops): (8 × 3) + (15 × 5) = 99
6. **AD** (Apartment Penalty): 15 × 3 = 45
7. **Stairs Penalty**: 20
8. **Parking Penalty**: 0.8 × 30 = 24

**Total Score**: 25 + 50 + 47 + 100 + 99 + 45 + 20 + 24 = **410 points**

**Grade**: Easy (≤ 650)
**Credits**: 1

## Credit Usage System

### Daily Accumulation
- Credits are tracked daily for each driver
- Easy routes: 1 credit
- Medium routes: 2 credits
- Hard routes: 3 credits

### Weekly & Monthly Balancing
The system ensures fair distribution by:
1. Tracking each driver's route history (Easy/Medium/Hard count)
2. Balancing workload so each driver gets a fair mix
3. Considering driver health status and fatigue scores
4. Allowing drivers to use accumulated credits for lighter routes

### Fairness Algorithm
The AI dispatch system considers:
- **Weekly balance**: How many Easy/Medium/Hard routes each driver completed
- **Fatigue score**: Higher fatigue = lighter routes
- **Health status**: Restricted drivers get easier routes
- **Credit balance**: Drivers can request easier routes using credits
- **Team fairness**: Ensures no driver is consistently overworked

## Implementation Details

### Database Storage
Each route stores:
- `route_score`: The calculated numerical score
- `route_credits`: The credit value (1, 2, or 3)
- `grade`: The assigned grade (EASY, MEDIUM, HARD)
- `grade_reason`: Detailed explanation with breakdown

### API Response Format
```json
{
  "route_id": 123,
  "grade": "MEDIUM",
  "route_score": 850,
  "route_credits": 2,
  "grade_reason": "Route Score: 850 (Medium, 2 credits). Breakdown: Packages: 30 + Weight: 60 + Distance: 45 + Time: 100 + Stops: 120. Key factors: moderate packages (5-10kg), moderate delivery time (4-6h), many apartment deliveries (18)"
}
```

## Benefits

1. **Transparency**: Drivers understand exactly why they received a route
2. **Fairness**: Mathematical formula ensures consistent grading
3. **Accountability**: All calculations are logged and auditable
4. **Flexibility**: System adapts to real-world conditions (traffic, weather, etc.)
5. **Driver Wellbeing**: Considers health, fatigue, and work-life balance

## Real-World Application

The system uses actual data:
- GPS coordinates for accurate distance calculation
- Package manifests for weight and count
- Historical traffic patterns for time estimation
- Building data for elevator/stairs information
- Driver feedback for continuous improvement

This ensures the grading system reflects real delivery challenges and maintains fairness across the entire driver fleet.
