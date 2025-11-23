class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final UserType userType;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isApproved;
  final UserProfile? profile;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isApproved = false,
    this.profile,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      userType: UserType.values.firstWhere(
        (type) => type.name == json['userType'],
        orElse: () => UserType.steward,
      ),
      profileImageUrl: json['profileImageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] is int 
          ? (json['isActive'] as int) == 1 
          : (json['isActive'] as bool? ?? true),
      isApproved: json['isApproved'] is int 
          ? (json['isApproved'] as int) == 1 
          : (json['isApproved'] as bool? ?? false),
      profile: json['profile'] != null 
          ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'isApproved': isApproved ? 1 : 0,
      'profile': profile?.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    UserType? userType,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isApproved,
    UserProfile? profile,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isApproved: isApproved ?? this.isApproved,
      profile: profile ?? this.profile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, userType: $userType)';
  }
}

enum UserType {
  steward('Steward'),
  siasteward('SIA Steward'),
  manager('Manager'),
  secondaryAdmin('Secondary Admin'),
  seniorAdmin('Senior Admin');

  const UserType(this.displayName);
  final String displayName;
}

class UserProfile {
  final String userId;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final List<String> certifications;
  final double? hourlyRate;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final bool isAvailableForShifts;
  final List<String> preferredLocations;

  UserProfile({
    required this.userId,
    this.licenseNumber,
    this.licenseExpiry,
    this.certifications = const [],
    this.hourlyRate,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.isAvailableForShifts = true,
    this.preferredLocations = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String,
      licenseNumber: json['licenseNumber'] as String?,
      licenseExpiry: json['licenseExpiry'] != null 
          ? DateTime.parse(json['licenseExpiry'] as String)
          : null,
      certifications: List<String>.from(json['certifications'] ?? []),
      hourlyRate: json['hourlyRate']?.toDouble(),
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      isAvailableForShifts: json['isAvailableForShifts'] is int 
          ? (json['isAvailableForShifts'] as int) == 1 
          : (json['isAvailableForShifts'] as bool? ?? true),
      preferredLocations: List<String>.from(json['preferredLocations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry?.toIso8601String(),
      'certifications': certifications,
      'hourlyRate': hourlyRate,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'isAvailableForShifts': isAvailableForShifts ? 1 : 0,
      'preferredLocations': preferredLocations,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? licenseNumber,
    DateTime? licenseExpiry,
    List<String>? certifications,
    double? hourlyRate,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    bool? isAvailableForShifts,
    List<String>? preferredLocations,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      certifications: certifications ?? this.certifications,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isAvailableForShifts: isAvailableForShifts ?? this.isAvailableForShifts,
      preferredLocations: preferredLocations ?? this.preferredLocations,
    );
  }
}