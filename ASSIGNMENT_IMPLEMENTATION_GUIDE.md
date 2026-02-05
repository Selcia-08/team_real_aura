# Route Assignment System - Complete Implementation Guide

## ✅ Backend Status

### Database Setup
- ✓ Routes table has `route_score` and `route_credits` columns
- ✓ Routes have proper grade enum (EASY, MEDIUM, HARD)
- ✓ Assignments table is ready
- ✓ 5 test assignments created with full details

### Current Assignments in Database:
1. **Alex Driver** → Downtown (Easy, 1 credit, 2.5km away)
2. **Sam Tired** → Suburbs (Medium, 2 credits, 4.0km away)
3. **Jamie Fresh** → Uptown (Hard, 3 credits, 5.5km away)
4. **Taylor Swift** → Shopping District (Easy, 1 credit, 7.0km away)
5. **NAVEEN** → Industrial Zone (Hard, 3 credits, 8.5km away)

### API Endpoints Available:
- `GET /assignments?driver_id={id}` - Get driver's assignments
- `POST /assignments/{id}/respond` - Accept/decline assignment
- `GET /users/{id}` - Get driver details

## 🔧 What Needs to be Fixed

### 1. API Service (lib/services/api_service.dart)
Add methods to fetch and respond to assignments:

```dart
// Get driver assignments
Future<List<Map<String, dynamic>>> getDriverAssignments(int driverId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/assignments?driver_id=$driverId'),
  );
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  }
  throw Exception('Failed to load assignments');
}

// Respond to assignment
Future<Map<String, dynamic>> respondToAssignment(
  int assignmentId,
  String action, {
  String? reason,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/assignments/$assignmentId/respond'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'action': action,
      'decline_reason': reason,
    }),
  );
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  throw Exception('Failed to respond to assignment');
}
```

### 2. Driver Dashboard (lib/screens/driver_dashboard_screen.dart)
Add assignment fetching and display:

```dart
class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  List<Map<String, dynamic>> assignments = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      // Fetch assignments
      final assignmentData = await ApiService().getDriverAssignments(widget.userId);
      setState(() {
        assignments = assignmentData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }
  
  // Build assignment card
  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final route = assignment['route'];
    final grade = route['grade'] ?? 'MEDIUM';
    final score = route['route_score'] ?? 0;
    final credits = route['route_credits'] ?? 1;
    
    return Card(
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route title and grade badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    route['area'] ?? 'Route',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildGradeBadge(grade, credits),
              ],
            ),
            const SizedBox(height: 12),
            
            // Route score
            Text(
              'Route Score: $score ($grade, $credits credits)',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            
            // Geolocation
            const SizedBox(height: 8),
            Text(
              'Start: (${route['start_lat']}, ${route['start_lng']})',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
            ),
            Text(
              'End: (${route['end_lat']}, ${route['end_lng']})',
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
            ),
            
            // Package info
            const SizedBox(height: 8),
            Text(
              'Packages: ${route['package_count']} | Weight: ${route['weight_kg']}kg',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            
            // Assignment reason
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                assignment['explanation'] ?? 'No explanation provided',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              ),
            ),
            
            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToAssignment(assignment, 'accept'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeclineDialog(assignment),
                    icon: const Icon(Icons.close),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradeBadge(String grade, int credits) {
    Color badgeColor;
    IconData icon;
    
    switch (grade.toUpperCase()) {
      case 'EASY':
        badgeColor = Colors.green;
        icon = Icons.sentiment_satisfied;
        break;
      case 'MEDIUM':
        badgeColor = Colors.orange;
        icon = Icons.sentiment_neutral;
        break;
      case 'HARD':
        badgeColor = Colors.red;
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            '$grade ($credits★)',
            style: GoogleFonts.outfit(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🚀 Quick Start Commands

### 1. Start Backend
```bash
python -m uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

### 2. Create Test Assignments (Already Done!)
```bash
python quick_start_assignments.py
```

### 3. Test API
```bash
# Get assignments for driver 1
Invoke-WebRequest -Uri "http://127.0.0.1:8000/assignments?driver_id=1" -UseBasicParsing

# Accept assignment
Invoke-WebRequest -Uri "http://127.0.0.1:8000/assignments/1/respond" -Method Post -Body '{"action":"accept"}' -ContentType "application/json" -UseBasicParsing
```

### 4. Run Flutter App
```bash
flutter run -d windows
```

## 📊 Assignment Display Features

Each assignment card shows:
1. ✅ **Route Name** (e.g., "Downtown")
2. ✅ **Grade Badge** (Easy/Medium/Hard with color coding)
3. ✅ **Route Score** (e.g., "Route Score: 450 (Easy, 1 credits)")
4. ✅ **Credits** (1-3 stars)
5. ✅ **Geolocation Coordinates** (Start and End GPS)
6. ✅ **Package Info** (Count and weight)
7. ✅ **Assignment Reason** (Why this route was assigned)
8. ✅ **Action Buttons** (Accept/Decline)

## 🎨 Grade Condition Options

When a driver crosses grade conditions (e.g., high fatigue), the system:
1. Shows a warning badge on the assignment
2. Provides options to:
   - Accept with acknowledgment
   - Decline with reason
   - Request easier route (uses credits)

## 📝 Next Steps

1. **Update API Service** - Add assignment methods
2. **Update Driver Dashboard** - Add assignment display
3. **Test in Flutter App** - Verify assignments appear
4. **Add Grade Warnings** - Show alerts for condition violations

## ✨ Current Status

- ✅ Backend fully functional
- ✅ Database has 5 test assignments
- ✅ API endpoints working
- ✅ Intelligent dispatch system ready
- ⏳ Frontend needs assignment display implementation

The backend is 100% ready! Just need to add the frontend code to display the assignments.
