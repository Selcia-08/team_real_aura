import 'package:flutter/material.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String employeeId;
  final String role;
  final String locationId;
  final double fatigueScore;
  final String healthStatus;
  final int credits;
  final int bonusCredits;
  final bool isAvailable;
  final bool hasMedicalExemption;
  final String? dob;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.role,
    required this.locationId,
    required this.fatigueScore,
    required this.healthStatus,
    required this.credits,
    required this.bonusCredits,
    required this.isAvailable,
    required this.hasMedicalExemption,
    this.dob,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      employeeId: json['employee_id'] ?? '',
      role: json['role'] ?? 'driver',
      locationId: json['location_id'] ?? '',
      fatigueScore: (json['fatigue_score'] ?? 0).toDouble(),
      healthStatus: json['health_status'] ?? 'Normal',
      credits: json['credits'] ?? 0,
      bonusCredits: json['bonus_credits'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      hasMedicalExemption: json['has_medical_exemption'] ?? false,
      dob: json['dob'],
    );
  }
}

class RouteModel {
  final int id;
  final String description;
  final String area;
  final String locationId;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final int packageCount;
  final double weightKg;
  final int grade;
  final String? gradeReason;
  final int? predictedTimeMinutes;
  final double? terrainDifficulty;
  final int? routeScore;
  final int? routeCredits;

  RouteModel({
    required this.id,
    required this.description,
    required this.area,
    required this.locationId,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.packageCount,
    required this.weightKg,
    required this.grade,
    this.gradeReason,
    this.predictedTimeMinutes,
    this.terrainDifficulty,
    this.routeScore,
    this.routeCredits,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      description: json['description'],
      area: json['area'],
      locationId: json['location_id'] ?? '',
      startLat: (json['start_lat'] ?? 0).toDouble(),
      startLng: (json['start_lng'] ?? 0).toDouble(),
      endLat: (json['end_lat'] ?? 0).toDouble(),
      endLng: (json['end_lng'] ?? 0).toDouble(),
      packageCount: json['package_count'] ?? 0,
      weightKg: (json['weight_kg'] ?? 0).toDouble(),
      grade: json['grade'] ?? 2,
      gradeReason: json['grade_reason'],
      predictedTimeMinutes: json['predicted_time_minutes'],
      terrainDifficulty: json['terrain_difficulty']?.toDouble(),
      routeScore: json['route_score'],
      routeCredits: json['route_credits'],
    );
  }

  String get gradeLabel {
    if (grade == 1) return "Easy";
    if (grade == 2) return "Medium";
    if (grade == 3) return "Hard";
    return "Unknown";
  }

  Color get gradeColor {
    if (grade == 1) return const Color(0xFF4CAF50); // Green
    if (grade == 2) return const Color(0xFFFF9800); // Orange
    if (grade == 3) return const Color(0xFFF44336); // Red
    return Colors.grey;
  }
}

class Assignment {
  final int id;
  final int driverId;
  final int routeId;
  final DateTime assignedDate;
  final String status;
  final String explanation;
  final String assignmentReason;
  final int reassignmentBonus;
  final RouteModel? route;

  Assignment({
    required this.id,
    required this.driverId,
    required this.routeId,
    required this.assignedDate,
    required this.status,
    required this.explanation,
    required this.assignmentReason,
    required this.reassignmentBonus,
    this.route,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      driverId: json['driver_id'],
      routeId: json['route_id'],
      assignedDate: DateTime.parse(json['assigned_date']),
      status: json['status'],
      explanation: json['explanation'],
      assignmentReason: json['assignment_reason'] ?? '',
      reassignmentBonus: json['reassignment_bonus'] ?? 0,
      route: json['route'] != null ? RouteModel.fromJson(json['route']) : null,
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isDeclined => status.toUpperCase() == 'DECLINED';
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String notificationType;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.notificationType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      notificationType: json['notification_type'] ?? '',
    );
  }
}

class DashboardStats {
  final int totalDrivers;
  final int activeDrivers;
  final int totalRoutesToday;
  final int pendingAssignments;
  final int completedToday;
  final double avgFatigue;

  DashboardStats({
    required this.totalDrivers,
    required this.activeDrivers,
    required this.totalRoutesToday,
    required this.pendingAssignments,
    required this.completedToday,
    required this.avgFatigue,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDrivers: json['total_drivers'] ?? 0,
      activeDrivers: json['active_drivers'] ?? 0,
      totalRoutesToday: json['total_routes_today'] ?? 0,
      pendingAssignments: json['pending_assignments'] ?? 0,
      completedToday: json['completed_today'] ?? 0,
      avgFatigue: (json['avg_fatigue'] ?? 0).toDouble(),
    );
  }
}
