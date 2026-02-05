import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService api = ApiService();
  List<User> users = [];
  User? currentUser;
  bool isLoading = true;
  List<Assignment> assignments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Try to populate first if empty?
      // For now just get users.
      users = await api.getDrivers();
      if (users.isEmpty) {
        await api.populateDemoData();
        users = await api.getDrivers();
      }
      
      if (users.isNotEmpty) {
        setState(() {
          currentUser = users.first; // Default
          isLoading = false;
        });
        _loadAssignments();
      }
    } catch (e) {
      print("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadAssignments() async {
    if (currentUser == null) return;
    try {
      final data = await api.getAssignments(currentUser!.id);
      setState(() {
        assignments = data;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _runDispatch() async {
    setState(() => isLoading = true);
    await api.runDispatch();
    await _loadData(); // Reload everything
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("FairDispatch AI"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          DropdownButton<User>(
            value: currentUser,
            dropdownColor: const Color(0xFF2C2C2C),
            underline: Container(),
            icon: const Icon(Icons.person, color: Colors.white),
            items: users.map((User user) {
              return DropdownMenuItem<User>(
                value: user,
                child: Text(user.name, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (User? newValue) {
              setState(() {
                currentUser = newValue;
              });
              _loadAssignments();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
          ),
        ),
        child: currentUser?.role == 'admin' ? _buildAdminView() : _buildDriverView(),
      ),
      floatingActionButton: currentUser?.role == 'admin' || true // Allow anyone to run dispatch for demo
          ? FloatingActionButton.extended(
              onPressed: _runDispatch,
              label: const Text("Run Dispatch"),
              icon: const Icon(Icons.bolt),
              backgroundColor: const Color(0xFF6C63FF),
            )
          : null,
    );
  }

  Widget _buildDriverView() {
    if (assignments.isEmpty) {
      return const Center(child: Text("No assignments yet. Wait for dispatch.", style: TextStyle(color: Colors.white70)));
    }
    
    // Show latest assignment
    final assignment = assignments.last;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildAssignmentCard(assignment),
          const SizedBox(height: 20),
          _buildStatsRow(),
          const SizedBox(height: 20),
          _buildMapSection(),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(child: Text(user.name[0])),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Fatigue: ${user.fatigueScore} | Credits: ${user.credits}"),
            trailing: Chip(
              label: Text(user.healthStatus),
              backgroundColor: user.healthStatus == 'Restricted' ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hello, ${currentUser?.name.split(' ')[0]}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const Text("Here is your daily briefing.", style: TextStyle(color: Colors.white60)),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    Color gradeColor = Colors.blue;
    if (assignment.route?.grade == 3) gradeColor = Colors.red;
    if (assignment.route?.grade == 1) gradeColor = Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("TODAY'S ROUTE", style: TextStyle(color: Colors.white.withOpacity(0.5), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gradeColor),
                ),
                child: Text(
                  assignment.route?.gradeLabel.toUpperCase() ?? "UNKNOWN", 
                  style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(assignment.explanation, style: const TextStyle(fontSize: 18, height: 1.5, fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70),
              const SizedBox(width: 10),
              Text(assignment.route?.area ?? "Unknown Area", style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
           Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.white70),
              const SizedBox(width: 10),
              Text("${assignment.route?.description}", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Credits", "${currentUser?.credits}", Icons.stars, Colors.amber)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Fatigue", "${currentUser?.fatigueScore.round()}%", Icons.battery_alert, Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(40.7128, -74.0060), // New York
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.fds',
            ),
          ],
        ),
      ),
    );
  }
}
