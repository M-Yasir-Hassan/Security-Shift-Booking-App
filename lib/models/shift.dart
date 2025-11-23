class Shift {
  final String id;
  final String title;
  final String description;
  final String locationId;
  final String locationName;
  final String locationAddress;
  final DateTime startTime;
  final DateTime endTime;
  final double hourlyRate;
  final int requiredGuards;
  final int assignedGuards;
  final int? requiredSiaGuards;
  final int? requiredStewardGuards;
  final ShiftStatus status;
  final ShiftType shiftType;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> requiredCertifications;
  final String? specialInstructions;
  final String? uniformRequirements;
  final bool isUrgent;
  final List<ShiftAssignment> assignments;

  Shift({
    required this.id,
    required this.title,
    required this.description,
    required this.locationId,
    required this.locationName,
    required this.locationAddress,
    required this.startTime,
    required this.endTime,
    required this.hourlyRate,
    required this.requiredGuards,
    this.assignedGuards = 0,
    this.requiredSiaGuards,
    this.requiredStewardGuards,
    required this.status,
    required this.shiftType,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.requiredCertifications = const [],
    this.specialInstructions,
    this.uniformRequirements,
    this.isUrgent = false,
    this.assignments = const [],
  });

  Duration get duration => endTime.difference(startTime);
  
  double get totalPay => duration.inHours * hourlyRate;
  
  bool get isFullyStaffed => assignedGuards >= requiredGuards;
  
  bool get isActive => status == ShiftStatus.active;
  
  bool get canBeBooked => 
      status == ShiftStatus.open && 
      assignedGuards < requiredGuards &&
      startTime.isAfter(DateTime.now());

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      locationAddress: json['locationAddress'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      requiredGuards: json['requiredGuards'] as int,
      assignedGuards: json['assignedGuards'] as int? ?? 0,
      requiredSiaGuards: json['requiredSiaGuards'] as int?,
      requiredStewardGuards: json['requiredStewardGuards'] as int?,
      status: ShiftStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ShiftStatus.open,
      ),
      shiftType: ShiftType.values.firstWhere(
        (type) => type.name == json['shiftType'],
        orElse: () => ShiftType.stewardShift,
      ),
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      requiredCertifications: List<String>.from(json['requiredCertifications'] ?? []),
      specialInstructions: json['specialInstructions'] as String?,
      uniformRequirements: json['uniformRequirements'] as String?,
      isUrgent: json['isUrgent'] is int 
          ? (json['isUrgent'] as int) == 1 
          : (json['isUrgent'] as bool? ?? false),
      assignments: (json['assignments'] as List<dynamic>?)
          ?.map((assignment) => ShiftAssignment.fromJson(assignment as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'locationId': locationId,
      'locationName': locationName,
      'locationAddress': locationAddress,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'hourlyRate': hourlyRate,
      'requiredGuards': requiredGuards,
      'assignedGuards': assignedGuards,
      'requiredSiaGuards': requiredSiaGuards,
      'requiredStewardGuards': requiredStewardGuards,
      'status': status.name,
      'shiftType': shiftType.name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'requiredCertifications': requiredCertifications,
      'specialInstructions': specialInstructions,
      'uniformRequirements': uniformRequirements,
      'isUrgent': isUrgent ? 1 : 0,
      'assignments': assignments.map((assignment) => assignment.toJson()).toList(),
    };
  }

  Shift copyWith({
    String? id,
    String? title,
    String? description,
    String? locationId,
    String? locationName,
    String? locationAddress,
    DateTime? startTime,
    DateTime? endTime,
    double? hourlyRate,
    int? requiredGuards,
    int? assignedGuards,
    int? requiredSiaGuards,
    int? requiredStewardGuards,
    ShiftStatus? status,
    ShiftType? shiftType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? requiredCertifications,
    String? specialInstructions,
    bool? isUrgent,
    List<ShiftAssignment>? assignments,
  }) {
    return Shift(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      locationAddress: locationAddress ?? this.locationAddress,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      requiredGuards: requiredGuards ?? this.requiredGuards,
      assignedGuards: assignedGuards ?? this.assignedGuards,
      requiredSiaGuards: requiredSiaGuards ?? this.requiredSiaGuards,
      requiredStewardGuards: requiredStewardGuards ?? this.requiredStewardGuards,
      status: status ?? this.status,
      shiftType: shiftType ?? this.shiftType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requiredCertifications: requiredCertifications ?? this.requiredCertifications,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      isUrgent: isUrgent ?? this.isUrgent,
      assignments: assignments ?? this.assignments,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shift && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Shift(id: $id, title: $title, location: $locationName, startTime: $startTime)';
  }
}

enum ShiftStatus {
  open('Open'),
  active('Active'),
  completed('Completed'),
  cancelled('Cancelled'),
  inProgress('In Progress');

  const ShiftStatus(this.displayName);
  final String displayName;
}

enum ShiftType {
  stewardShift('Steward Shift'),
  siaShift('SIA Shift'),
  emergency('Emergency'),
  event('Event'),
  overtime('Overtime');

  const ShiftType(this.displayName);
  final String displayName;
}

class ShiftAssignment {
  final String id;
  final String shiftId;
  final String guardId;
  final String guardName;
  final AssignmentStatus status;
  final DateTime assignedAt;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? notes;
  final double? actualHours;

  ShiftAssignment({
    required this.id,
    required this.shiftId,
    required this.guardId,
    required this.guardName,
    required this.status,
    required this.assignedAt,
    this.checkedInAt,
    this.checkedOutAt,
    this.notes,
    this.actualHours,
  });

  bool get isCheckedIn => checkedInAt != null && checkedOutAt == null;
  bool get isCompleted => checkedInAt != null && checkedOutAt != null;

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    return ShiftAssignment(
      id: json['id'] as String,
      shiftId: json['shiftId'] as String,
      guardId: json['guardId'] as String,
      guardName: json['guardName'] as String,
      status: AssignmentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AssignmentStatus.assigned,
      ),
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      checkedInAt: json['checkedInAt'] != null 
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
      checkedOutAt: json['checkedOutAt'] != null 
          ? DateTime.parse(json['checkedOutAt'] as String)
          : null,
      notes: json['notes'] as String?,
      actualHours: json['actualHours']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'guardId': guardId,
      'guardName': guardName,
      'status': status.name,
      'assignedAt': assignedAt.toIso8601String(),
      'checkedInAt': checkedInAt?.toIso8601String(),
      'checkedOutAt': checkedOutAt?.toIso8601String(),
      'notes': notes,
      'actualHours': actualHours,
    };
  }

  ShiftAssignment copyWith({
    String? id,
    String? shiftId,
    String? guardId,
    String? guardName,
    AssignmentStatus? status,
    DateTime? assignedAt,
    DateTime? checkedInAt,
    DateTime? checkedOutAt,
    String? notes,
    double? actualHours,
  }) {
    return ShiftAssignment(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      notes: notes ?? this.notes,
      actualHours: actualHours ?? this.actualHours,
    );
  }
}

enum AssignmentStatus {
  assigned('Assigned'),
  confirmed('Confirmed'),
  checkedIn('Checked In'),
  completed('Completed'),
  cancelled('Cancelled'),
  noShow('No Show');

  const AssignmentStatus(this.displayName);
  final String displayName;
}