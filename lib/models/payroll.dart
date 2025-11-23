class PayrollEntry {
  final String id;
  final String userId;
  final String shiftId;
  final String shiftTitle;
  final DateTime shiftDate;
  final DateTime startTime;
  final DateTime endTime;
  final double hoursWorked;
  final double hourlyRate;
  final double totalPay;
  final PayrollStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? notes;

  PayrollEntry({
    required this.id,
    required this.userId,
    required this.shiftId,
    required this.shiftTitle,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.totalPay,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.notes,
  });

  bool get isConfirmed => status == PayrollStatus.confirmed;
  bool get isPending => status == PayrollStatus.pending;

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      shiftId: json['shiftId'] as String,
      shiftTitle: json['shiftTitle'] as String,
      shiftDate: DateTime.parse(json['shiftDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      hoursWorked: (json['hoursWorked'] as num).toDouble(),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      totalPay: (json['totalPay'] as num).toDouble(),
      status: PayrollStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PayrollStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt'] as String) 
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'shiftId': shiftId,
      'shiftTitle': shiftTitle,
      'shiftDate': shiftDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'hoursWorked': hoursWorked,
      'hourlyRate': hourlyRate,
      'totalPay': totalPay,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  PayrollEntry copyWith({
    String? id,
    String? userId,
    String? shiftId,
    String? shiftTitle,
    DateTime? shiftDate,
    DateTime? startTime,
    DateTime? endTime,
    double? hoursWorked,
    double? hourlyRate,
    double? totalPay,
    PayrollStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? notes,
  }) {
    return PayrollEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shiftId: shiftId ?? this.shiftId,
      shiftTitle: shiftTitle ?? this.shiftTitle,
      shiftDate: shiftDate ?? this.shiftDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalPay: totalPay ?? this.totalPay,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayrollEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PayrollEntry(id: $id, shiftTitle: $shiftTitle, hoursWorked: $hoursWorked, totalPay: $totalPay, status: $status)';
  }
}

enum PayrollStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  paid('Paid'),
  disputed('Disputed');

  const PayrollStatus(this.displayName);
  final String displayName;
}

class MonthlyPayroll {
  final String userId;
  final int year;
  final int month;
  final List<PayrollEntry> entries;
  final double totalHours;
  final double totalEarnings;
  final int confirmedShifts;
  final int pendingShifts;

  MonthlyPayroll({
    required this.userId,
    required this.year,
    required this.month,
    required this.entries,
    required this.totalHours,
    required this.totalEarnings,
    required this.confirmedShifts,
    required this.pendingShifts,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  factory MonthlyPayroll.fromEntries(
    String userId,
    int year,
    int month,
    List<PayrollEntry> entries,
  ) {
    final totalHours = entries.fold<double>(0, (sum, entry) => sum + entry.hoursWorked);
    final totalEarnings = entries.fold<double>(0, (sum, entry) => sum + entry.totalPay);
    final confirmedShifts = entries.where((entry) => entry.isConfirmed).length;
    final pendingShifts = entries.where((entry) => entry.isPending).length;

    return MonthlyPayroll(
      userId: userId,
      year: year,
      month: month,
      entries: entries,
      totalHours: totalHours,
      totalEarnings: totalEarnings,
      confirmedShifts: confirmedShifts,
      pendingShifts: pendingShifts,
    );
  }
}
