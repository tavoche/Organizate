class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final DateTime birthDate;
  final bool notificationsPreference;
  final String themePreference;
  final String location;
  final String userType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.birthDate,
    required this.notificationsPreference,
    required this.themePreference,
    required this.location,
    required this.userType,
  });

  // Factory constructor para crear un usuario desde un mapa (útil para JSON)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      birthDate: map['birthDate'] != null 
          ? (map['birthDate'] is DateTime 
              ? map['birthDate'] 
              : DateTime.parse(map['birthDate']))
          : DateTime.now(),
      notificationsPreference: map['notificationsPreference'] ?? true,
      themePreference: map['themePreference'] ?? 'light',
      location: map['location'] ?? '',
      userType: map['userType'] ?? 'standard',
    );
  }

  // Método para convertir el usuario a un mapa (útil para JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'birthDate': birthDate.toIso8601String(),
      'notificationsPreference': notificationsPreference,
      'themePreference': themePreference,
      'location': location,
      'userType': userType,
    };
  }

  // Método para crear una copia del usuario con algunos campos modificados
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    DateTime? birthDate,
    bool? notificationsPreference,
    String? themePreference,
    String? location,
    String? userType,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      notificationsPreference: notificationsPreference ?? this.notificationsPreference,
      themePreference: themePreference ?? this.themePreference,
      location: location ?? this.location,
      userType: userType ?? this.userType,
    );
  }
}

