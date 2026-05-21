class AlertModel {
  final String id;
  final String title;
  final String description;
  final String type; // 'flood', 'earthquake', 'fire', 'cyclone', 'other'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String createdBy; // user id
  bool isResolved;

  AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.createdBy,
    this.isResolved = false,
  });

  factory AlertModel.fromMap(Map<String, dynamic> map) {
    return AlertModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'other',
      severity: map['severity'] ?? 'medium',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      createdBy: map['createdBy'] ?? '',
      isResolved: map['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isResolved': isResolved,
    };
  }
}
