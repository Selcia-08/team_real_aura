import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  final String locationId;
  final int adminId;

  const AdminDashboardScreen({
    super.key,
    required this.locationId,
    required this.adminId,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  DashboardStats? stats;
  List<User> drivers = [];
  List<Assignment> assignments = [];
  Map<String, dynamic>? policy;
  bool isLoading = true;
  Timer? _refreshTimer;
  late TabController _tabController;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 Tabs now
    _loadData();
    
    // Auto-refresh every 6 seconds as requested
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final dashboardStats = await _api.getAdminDashboard(widget.locationId);
      final locationDrivers = await _api.getDrivers(locationId: widget.locationId);
      final weeklyPolicy = await _api.getWeeklyPolicy(widget.locationId);
      final allAssignments = await _api.getAssignments(); // Get all assignments

      if (mounted) {
        setState(() {
          stats = dashboardStats;
          drivers = locationDrivers;
          policy = weeklyPolicy;
          assignments = allAssignments;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _runDispatch() async {
    setState(() => isLoading = true);
    
    try {
      final result = await _api.runDispatch(widget.locationId);
      
      final message = result['message'];
      final count = result['assignments_count'];
      
      // Determine if it was a "success" or "warning" based on count
      final isWarning = count == 0;
      final color = isWarning ? Colors.orange : Colors.green;

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(isWarning ? 'Dispatch Notice' : 'Dispatch Success', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isWarning ? Icons.info_outline : Icons.check_circle_outline, color: color, size: 60),
                const SizedBox(height: 16),
                Text(message, style: GoogleFonts.outfit(color: Colors.white70), textAlign: TextAlign.center),
                if (!isWarning) ...[
                  const SizedBox(height: 8),
                  Text('$count assignments made.', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
      
      // Refresh data to show new assignments
      _loadData();
    } catch (e) {
      print('Dispatch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _populateDemo() async {
    setState(() => isLoading = true);
    
    try {
      await _api.populateDemoData(locationId: widget.locationId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo data populated!'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _addDriver() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final ageController = TextEditingController();
    final dobController = TextEditingController();
    final nativeController = TextEditingController();
    final experienceController = TextEditingController();
    String licenseType = 'Light Vehicle'; // Default
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: Text('Add New Driver', style: GoogleFonts.outfit(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo Placeholder
                Center(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt, color: Colors.white54, size: 30),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTextField(nameController, 'Full Name'),
                const SizedBox(height: 10),
                _buildTextField(emailController, 'Email'),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField(ageController, 'Age', isNumber: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(dobController, 'DOB (DDMMYYYY)', isNumber: true)),
                  ],
                ),
                const SizedBox(height: 10),
                
                _buildTextField(nativeController, 'Native Place'),
                const SizedBox(height: 10),
                _buildTextField(experienceController, 'Experience (Years)', isNumber: true),
                const SizedBox(height: 10),
                
                // License Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26, 
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24)
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: licenseType,
                      dropdownColor: const Color(0xFF2C2C2C),
                      isExpanded: true,
                      style: GoogleFonts.outfit(color: Colors.white),
                      items: ['Light Vehicle', 'Heavy Vehicle', 'Hazardous'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => licenseType = val!),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Text(
                  'ID & Password will be auto-generated.',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty) {
                  return;
                }
                try {
                  // Call API to create driver
                  // We send fields, ID/PWD generated by backend
                  final newUser = await _api.createDriver({
                     "name": nameController.text,
                     "email": emailController.text,
                     "role": "DRIVER",
                     "location_id": widget.locationId,
                     // New Fields
                     "age": int.tryParse(ageController.text) ?? 0,
                     "dob": dobController.text,
                     "native_place": nativeController.text,
                     "experience_years": int.tryParse(experienceController.text) ?? 0,
                     "license_type": licenseType,
                     "photo_url": "" // Todo: Implement upload
                  });
                  
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  _loadData(); 
                  
                  // Show Credentials Dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2C2C2C),
                      title: Text('Driver Created Successfully', style: GoogleFonts.outfit(color: Colors.green)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Please share these credentials with the driver:', style: GoogleFonts.outfit(color: Colors.white70)),
                          const SizedBox(height: 16),
                          _buildCredentialRow('Employee ID', newUser.employeeId),
                          const SizedBox(height: 8),
                          _buildCredentialRow('Password', newUser.dob ?? 'pass123'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
              child: const Text('Add Employee'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          SelectableText(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isPassword = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Future<void> _generatePdf(User driver) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Driver Performance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 20),
              pw.Text('Name: ${driver.name}', style: const pw.TextStyle(fontSize: 18)),
              pw.Text('Employee ID: ${driver.employeeId}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Email: ${driver.email}', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Location ID: ${driver.locationId}', style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Health Status: ${driver.healthStatus}'),
                   pw.Text('Fatigue Score: ${driver.fatigueScore}'),
                ]
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Credits Balance: ${driver.credits}'),
                   pw.Text('Bonus Credits: ${driver.bonusCredits}'),
                ]
              ),
              pw.SizedBox(height: 20),
              pw.Text('This report serves as a snapshot of the driver\'s current metrics in the FairDispatch system.'),
              pw.Spacer(),
              pw.Text('Generated on ${DateTime.now().toString()}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Driver_${driver.employeeId}_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && stats == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            Text(
              widget.locationId,
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.people), text: 'Drivers'),
            Tab(icon: Icon(Icons.assignment), text: 'Assignments'),
            Tab(icon: Icon(Icons.map), text: 'Live Map'),
            Tab(icon: Icon(Icons.settings), text: 'Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent swipe for map interaction
        children: [
          _buildOverviewTab(),
          _buildDriversTab(),
          _buildAssignmentsTab(),
          _buildMapTab(),
          _buildPolicyTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runDispatch,
        label: Text('Run Dispatch', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.bolt),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (stats == null) return const Center(child: Text('No data'));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Drivers', '${stats!.totalDrivers}', Icons.people, const Color(0xFF6C63FF))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Active', '${stats!.activeDrivers}', Icons.check_circle, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Routes Today', '${stats!.totalRoutesToday}', Icons.local_shipping, const Color(0xFF03DAC6))),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', '${stats!.pendingAssignments}', Icons.pending, Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Completed', '${stats!.completedToday}', Icons.done_all, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Avg Fatigue', '${stats!.avgFatigue.round()}%', Icons.battery_alert, _getFatigueColor(stats!.avgFatigue))),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Fatigue Chart
            Text(
              'Team Fatigue Overview',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildFatigueChart(),
            
            const SizedBox(height: 30),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              'Run Intelligent Dispatch',
              Icons.bolt,
              const Color(0xFF6C63FF),
              _runDispatch,
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              'Populate Demo Data',
              Icons.data_object,
              Colors.blue,
              _populateDemo,
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              'Add New Dispatcher',
              Icons.person_add_alt_1,
              Colors.teal,
              () => _addDispatcher(),
            ),
            const SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildDriversTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0), // Above the main FAB
        child: FloatingActionButton(
          onPressed: _addDriver,
          backgroundColor: Colors.green,
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return _buildDriverCard(driver);
          },
        ),
      ),
    );
  }

  Widget _buildDriverCard(User driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                child: Text(
                  driver.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      driver.employeeId,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
                onPressed: () => _generatePdf(driver),
                tooltip: 'Download Report',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             decoration: BoxDecoration(
               color: _getHealthStatusColor(driver.healthStatus).withOpacity(0.2),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: _getHealthStatusColor(driver.healthStatus)),
             ),
             child: Text(
               'Health: ${driver.healthStatus}',
               style: GoogleFonts.outfit(
                 color: _getHealthStatusColor(driver.healthStatus),
                 fontWeight: FontWeight.bold,
                 fontSize: 12,
               ),
             ),
          ),
          const SizedBox(height: 12),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDriverStat('Fatigue', '${driver.fatigueScore.round()}%', _getFatigueColor(driver.fatigueScore)),
              _buildDriverStat('Credits', '${driver.credits}', Colors.amber),
              _buildDriverStat('Bonus', '${driver.bonusCredits}', Colors.green),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapTab() {
     // Using a fixed center for demo purposes or first driver's location if available
     // In a real app we would get real coordinates. Using Chennai/User's Location or defaulting to 13.0827, 80.2707 as in populate demo
     final center = LatLng(13.0827, 80.2707);
     
     return Stack(
       children: [
         FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
            ),
        children: [
          TileLayer(
             urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
             subdomains: const ['a', 'b', 'c', 'd'],
             userAgentPackageName: 'com.example.fds',
          ),
          MarkerLayer(
             markers: drivers.map<Marker>((driver) {
                // Simulate some random scatter around center for vis
                // hashCode based offset to verify consistency
                final latOffset = (driver.id * 1234 % 100) / 10000.0;
                final lngOffset = (driver.id * 5678 % 100) / 10000.0;
                
                return Marker(
                   point: LatLng(center.latitude + latOffset, center.longitude + lngOffset),
                   width: 80,
                   height: 80,
                   child: Column(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(4),
                         decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                         child: Icon(Icons.local_shipping, color: _getFatigueColor(driver.fatigueScore), size: 20),
                       ),
                       Container(
                         padding: const EdgeInsets.all(2),
                         color: Colors.black54,
                         child: Text(driver.name, style: const TextStyle(color: Colors.white, fontSize: 10)),
                       )
                     ],
                   ),
                );
              }).toList(),
            ),
          ],
        ),
      Positioned(
        right: 16,
        bottom: 100,
        child: Column(
          children: [
            FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: () => _mapController.move(center, 13),
              backgroundColor: const Color(0xFF6C63FF),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.small(
              heroTag: 'refresh_map',
              onPressed: _loadData,
              backgroundColor: const Color(0xFF1E1E1E),
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildDriverStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyTab() {
    if (policy == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Fairness Policy',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure weekly route distribution and credit system',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Route Targets
          _buildPolicySection(
            'Weekly Route Targets',
            [
              _buildPolicyItem('Easy Routes', '${policy!['easy_routes_target']}', Icons.trending_down, Colors.green),
              _buildPolicyItem('Medium Routes', '${policy!['medium_routes_target']}', Icons.trending_flat, Colors.orange),
              _buildPolicyItem('Hard Routes', '${policy!['hard_routes_target']}', Icons.trending_up, Colors.red),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Credit Rewards
          _buildPolicySection(
            'Credit Rewards',
            [
              _buildPolicyItem('Easy Route Credits', '${policy!['easy_route_credits']}', Icons.stars, Colors.amber),
              _buildPolicyItem('Medium Route Credits', '${policy!['medium_route_credits']}', Icons.stars, Colors.amber),
              _buildPolicyItem('Hard Route Credits', '${policy!['hard_route_credits']}', Icons.stars, Colors.amber),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Relaxation Conditions
          _buildPolicySection(
            'Relaxation Conditions',
            [
              _buildPolicyItem('Max Consecutive Hard Routes', '${policy!['max_consecutive_hard_routes']}', Icons.block, Colors.red),
              _buildPolicyItem('Fatigue Threshold', '${policy!['fatigue_threshold_for_restriction']}%', Icons.battery_alert, Colors.orange),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Auto-Dispatch
          _buildPolicySection(
            'Dispatch Rule',
            [
              _buildPolicyItem('Automatic AI Trigger', policy!['auto_dispatch_enabled'] == true ? 'ENABLED' : 'DISABLED', Icons.bolt, policy!['auto_dispatch_enabled'] == true ? Colors.blueAccent : Colors.white24),
              _buildPolicyItem('Scheduled Time', '${policy!['auto_dispatch_time']}', Icons.alarm, Colors.blueAccent),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Update Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showPolicyUpdateDialog(),
              icon: const Icon(Icons.edit),
              label: Text('Update Policy', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 60), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyUpdateDialog() {
    final easyController = TextEditingController(text: '${policy!['easy_routes_target']}');
    final mediumController = TextEditingController(text: '${policy!['medium_routes_target']}');
    final hardController = TextEditingController(text: '${policy!['hard_routes_target']}');
    final timeController = TextEditingController(text: '${policy!['auto_dispatch_time']}');
    bool autoEnabled = policy!['auto_dispatch_enabled'] == true;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Update Weekly Policy', style: GoogleFonts.outfit(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPolicyTextField('Easy Routes Target', easyController),
              const SizedBox(height: 12),
              _buildPolicyTextField('Medium Routes Target', mediumController),
              const SizedBox(height: 12),
              _buildPolicyTextField('Hard Routes Target', hardController),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setDialogState) => Column(
                  children: [
                    SwitchListTile(
                      title: Text('Enable Auto-Dispatch', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                      value: autoEnabled,
                      onChanged: (val) => setDialogState(() => autoEnabled = val),
                      activeColor: const Color(0xFF6C63FF),
                    ),
                    _buildPolicyTextField('Execution Time (HH:MM)', timeController),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.updateWeeklyPolicy(widget.locationId, {
                  'easy_routes_target': int.parse(easyController.text),
                  'medium_routes_target': int.parse(mediumController.text),
                  'hard_routes_target': int.parse(hardController.text),
                  'auto_dispatch_enabled': autoEnabled,
                  'auto_dispatch_time': timeController.text,
                });
                
                Navigator.pop(context);
                await _loadData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Policy updated!'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: Text('Update', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFatigueChart() {
    if (drivers.isEmpty) return const SizedBox();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= drivers.length) return const Text('');
                  return Text(
                    drivers[value.toInt()].name.split(' ')[0],
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.white.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: drivers.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.fatigueScore,
                  color: _getFatigueColor(entry.value.fatigueScore),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    if (assignments.isEmpty) return _buildEmptyState(message: 'No active assignments');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          return _buildAssignmentListItem(assignment);
        },
      ),
    );
  }

  Widget _buildAssignmentListItem(Assignment assignment) {
    final route = assignment.route;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                route?.area ?? 'Unknown Route',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildStatusBadge(assignment.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assigned to: ${assignment.driverId}', // In a real app we'd map ID to Name
            style: GoogleFonts.outfit(color: Colors.white70),
          ),
          if (route != null) ...[
             const SizedBox(height: 4),
             Text(
               'Grade: ${route.gradeLabel} | Score: ${route.routeScore ?? "N/A"}',
               style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
             ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.explanation,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, fontStyle: FontStyle.italic),
                ),
                if (assignment.assignmentReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  Text(
                    'AI ALLOCATION LOGIC:',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assignment.assignmentReason,
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
     Color color = Colors.orange;
     if (status == 'ACCEPTED') color = Colors.green;
     if (status == 'DECLINED') color = Colors.red;
     
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
       child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
     );
  }

  Future<void> _addDispatcher() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text('Add New Dispatcher', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Full Name'),
            const SizedBox(height: 12),
            _buildTextField(emailController, 'Email'),
            const SizedBox(height: 12),
            _buildTextField(passwordController, 'Password', isPassword: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _api.createDriver({
                  "name": nameController.text,
                  "email": emailController.text,
                  "password": passwordController.text,
                  "role": "DISPATCHER",
                  "location_id": widget.locationId,
                });
                Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                print(e);
              }
            },
            child: const Text('Add Dispatcher'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No data available'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 18)),
        ],
      ),
    );
  }

  Color _getHealthStatusColor(String status) {
    if (status.toUpperCase() == 'NORMAL') return Colors.green;
    if (status.toUpperCase() == 'CAUTION') return Colors.orange;
    return Colors.red;
  }

  Color _getFatigueColor(double fatigue) {
    if (fatigue < 40) return Colors.green;
    if (fatigue < 70) return Colors.orange;
    return Colors.red;
  }
}
