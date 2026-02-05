class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final double fatigueScore;
  final String healthStatus;
  final int credits;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.fatigueScore,
    required this.healthStatus,
    required this.credits,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'driver',
      fatigueScore: json['fatigue_score']?.toDouble() ?? 0.0,
      healthStatus: json['health_status'] ?? 'Normal',
      credits: json['credits'] ?? 0,
    );
  }
}

class RouteModel {
  final int id;
  final String description;
  final String area;
  final int grade; // 1, 2, 3

  RouteModel({
    required this.id,
    required this.description,
    required this.area,
    required this.grade,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      description: json['description'],
      area: json['area'],
      grade: json['grade'] ?? 2,
    );
  }
  
  String get gradeLabel {
    if (grade == 1) return "Easy";
    if (grade == 2) return "Medium";
    if (grade == 3) return "Hard";
    return "Unknown";
  }
}

class Assignment {
  final int id;
  final int driverId;
  final int routeId;
  final String status;
  final String explanation;
  final RouteModel? route;

  Assignment({
    required this.id,
    required this.driverId,
    required this.routeId,
    required this.status,
    required this.explanation,
    this.route,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      driverId: json['driver_id'],
      routeId: json['route_id'],
      status: json['status'],
      explanation: json['explanation'],
      route: json['route'] != null ? RouteModel.fromJson(json['route']) : null,
    );
  }
}
