class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final double? latitude;
  final double? longitude;
  final String role; // 'victim', 'volunteer', 'responder'

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.latitude,
    this.longitude,
    this.role = 'victim',
  });

  // Map theke UserModel banano (Firebase/SQLite er jonno)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      latitude: map['latitude'],
      longitude: map['longitude'],
      role: map['role'] ?? 'victim',
    );
  }

  // UserModel ke Map e convert kora
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
    };
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, role: $role)';
}
