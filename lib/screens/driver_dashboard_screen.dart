import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class DriverDashboardScreen extends StatefulWidget {
  final int userId;

  const DriverDashboardScreen({super.key, required this.userId});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  User? currentUser;
  List<Assignment> assignments = [];
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = await _api.getUser(widget.userId);
      final userAssignments = await _api.getAssignments(driverId: widget.userId);
      final userNotifications = await _api.getNotifications(widget.userId);

      if (mounted) {
        setState(() {
          currentUser = user;
          assignments = userAssignments;
          notifications = userNotifications;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _respondToAssignment(Assignment assignment, String action, {String? reason}) async {
    try {
      await _api.respondToAssignment(assignment.id, action, declineReason: reason);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'accept' ? 'Route accepted!' : 'Route declined'),
          backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
        ),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeclineDialog(Assignment assignment) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Decline Route', style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for declining this route:',
              style: GoogleFonts.outfit(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Not feeling well, personal emergency...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToAssignment(assignment, 'decline', reason: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Decline', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;

  Future<void> _launchNavigation(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('FairDispatch', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _tabController.animateTo(2),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.map), text: 'Routes'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildRoutesTab(),
          _buildNotificationsTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final pendingAssignments = assignments.where((a) => a.isPending).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            
            // Stats Row
            _buildStatsRow(),
            const SizedBox(height: 20),
            
            // Pending Assignments
            if (pendingAssignments.isNotEmpty) ...[
              Text(
                'Pending Routes',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ...pendingAssignments.map((assignment) => _buildAssignmentCard(assignment)),
            ] else ...[
              _buildEmptyState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  currentUser!.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      currentUser!.name.split(' ')[0],
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getHealthStatusColor(currentUser!.healthStatus).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getHealthStatusColor(currentUser!.healthStatus)),
                ),
                child: Text(
                  currentUser!.healthStatus,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Credits', '${currentUser!.credits}', Icons.stars, Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Bonus', '${currentUser!.bonusCredits}', Icons.card_giftcard, Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Fatigue', '${currentUser!.fatigueScore.round()}%', Icons.battery_alert, _getFatigueColor(currentUser!.fatigueScore))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    if (assignment.route == null) return const SizedBox();
    
    final route = assignment.route!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: route.gradeColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEW ASSIGNMENT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  if (route.routeCredits != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.purple, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${route.routeCredits} CR',
                            style: GoogleFonts.outfit(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: route.gradeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: route.gradeColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag, color: route.gradeColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          route.gradeLabel.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: route.gradeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // AI Math Calculation & Explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: const Color(0xFF6C63FF), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AI CALCULATION: ${route.routeScore ?? "N/A"} PTS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6C63FF),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    if (route.grade == 3 && currentUser!.fatigueScore > 60)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text("CONDITION RISK", style: GoogleFonts.outfit(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  assignment.explanation,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
                if (assignment.assignmentReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Text(
                    'AI ALLOCATION LOGIC:',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C63FF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignment.assignmentReason,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Route Details
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildRouteDetail(Icons.location_on, route.area),
              _buildRouteDetail(Icons.inventory_2, '${route.packageCount} pkgs'),
              _buildRouteDetail(Icons.scale, '${route.weightKg.toStringAsFixed(1)} kg'),
              if (route.predictedTimeMinutes != null)
                _buildRouteDetail(Icons.access_time, '${route.predictedTimeMinutes} min'),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Geolocation Details
          Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.blue, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Start: (${route.startLat.toStringAsFixed(4)}, ${route.startLng.toStringAsFixed(4)}) → End: (${route.endLat.toStringAsFixed(4)}, ${route.endLng.toStringAsFixed(4)})',
                  style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                ),
              ),
            ],
          ),
          
          if (assignment.reassignmentBonus > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${assignment.reassignmentBonus} Bonus Credits!',
                    style: GoogleFonts.outfit(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeclineDialog(assignment),
                  icon: const Icon(Icons.close),
                  label: Text('Decline', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToAssignment(assignment, 'accept'),
                  icon: const Icon(Icons.check),
                  label: Text('Accept', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildRoutesTab() {
    final acceptedAssignments = assignments.where((a) => a.isAccepted).toList();
    
    return acceptedAssignments.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acceptedAssignments.length,
            itemBuilder: (context, index) {
              final assignment = acceptedAssignments[index];
              return _buildRouteMapCard(assignment);
            },
          );
  }

  Widget _buildRouteMapCard(Assignment assignment) {
    if (assignment.route == null) return const SizedBox();
    
    final route = assignment.route!;
    final isHard = route.grade == 3;
    final isMedium = route.grade == 2;
    
    return Container(
      height: 400, // Taller for better view
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: route.gradeColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // 1. Premium Dark Map
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  (route.startLat + route.endLat) / 2, 
                  (route.startLng + route.endLng) / 2
                ),
                initialZoom: 14, // Zoomed in for "Street" closer feel
              ),
              children: [
                TileLayer(
                  // Premium Dark Mode Tiles
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.fds',
                ),
                // 2. Colored Route Path (Visualizing Difficulty)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: [
                        LatLng(route.startLat, route.startLng),
                        LatLng(route.endLat, route.endLng),
                      ],
                      strokeWidth: 4.0,
                      color: route.gradeColor,
                      // isDotted removed as it is not supported in this version
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(route.startLat, route.startLng),
                      width: 50,
                      height: 50,
                      child: _buildCustomMarker(Icons.my_location, Colors.white, Colors.blue),
                    ),
                    Marker(
                      point: LatLng(route.endLat, route.endLng),
                      width: 50,
                      height: 50,
                      child: _buildCustomMarker(Icons.flag_rounded, Colors.white, route.gradeColor),
                    ),
                  ],
                ),
              ],
            ),
            
            // 3. Floating Glassmorphic Info Card
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.95), // Semi-transparent
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               route.area,
                               style: GoogleFonts.outfit(
                                 fontSize: 18, 
                                 fontWeight: FontWeight.bold, 
                                 color: Colors.white
                               ),
                             ),
                             Text(
                               '${route.predictedTimeMinutes} min • ${const Distance().as(LengthUnit.Kilometer, LatLng(route.startLat, route.startLng), LatLng(route.endLat, route.endLng)).toStringAsFixed(1)} km',
                               style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                             ),
                           ],
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: route.gradeColor.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: route.gradeColor),
                           ),
                           child: Row(
                             children: [
                               Icon(
                                 isHard ? Icons.warning_amber : (isMedium ? Icons.terrain : Icons.thumb_up),
                                 color: route.gradeColor, 
                                 size: 14
                               ),
                               const SizedBox(width: 6),
                               Text(
                                 route.gradeLabel.toUpperCase(),
                                 style: GoogleFonts.outfit(
                                   color: route.gradeColor,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12,
                                 ),
                               ),
                             ],
                           ),
                         ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'AI PREDICTION: ${route.description}',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _launchNavigation(route.endLat, route.endLng),
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: Text('NAVIGATE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMarker(IconData icon, Color iconColor, Color bgColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: bgColor.withOpacity(0.6), blurRadius: 8)],
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return notifications.isEmpty
        ? _buildEmptyState(message: 'No notifications yet')
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? const Color(0xFF1E1E1E) : const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? Colors.white.withOpacity(0.05) : const Color(0xFF6C63FF).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getNotificationIcon(notification.notificationType),
            color: notification.isRead ? Colors.white54 : const Color(0xFF6C63FF),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notification.createdAt),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No pending routes'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(fontSize: 18, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Color _getHealthStatusColor(String status) {
    if (status == 'Normal') return Colors.green;
    if (status == 'Caution') return Colors.orange;
    return Colors.red;
  }

  Color _getFatigueColor(double fatigue) {
    if (fatigue < 40) return Colors.green;
    if (fatigue < 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getNotificationIcon(String type) {
    if (type.contains('route')) return Icons.local_shipping;
    if (type.contains('bonus')) return Icons.card_giftcard;
    return Icons.notifications;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
