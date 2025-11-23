class Booking {
  final String id;
  final String shiftId;
  final String guardId;
  final String guardName;
  final String shiftTitle;
  final String locationName;
  final DateTime shiftStartTime;
  final DateTime shiftEndTime;
  final double hourlyRate;
  final BookingStatus status;
  final DateTime bookedAt;
  final DateTime? confirmedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;
  final PaymentInfo? paymentInfo;

  Booking({
    required this.id,
    required this.shiftId,
    required this.guardId,
    required this.guardName,
    required this.shiftTitle,
    required this.locationName,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.hourlyRate,
    required this.status,
    required this.bookedAt,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.paymentInfo,
  });

  Duration get shiftDuration => shiftEndTime.difference(shiftStartTime);
  
  double get totalEarnings => shiftDuration.inHours * hourlyRate;
  
  bool get isActive => status == BookingStatus.confirmed;
  
  bool get canBeCancelled => 
      status == BookingStatus.pending || 
      status == BookingStatus.confirmed &&
      shiftStartTime.isAfter(DateTime.now().add(const Duration(hours: 24)));

  bool get isUpcoming => 
      (status == BookingStatus.confirmed || status == BookingStatus.pending) &&
      shiftStartTime.isAfter(DateTime.now());

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      shiftId: json['shiftId'] as String,
      guardId: json['guardId'] as String,
      guardName: json['guardName'] as String,
      shiftTitle: json['shiftTitle'] as String,
      locationName: json['locationName'] as String,
      shiftStartTime: DateTime.parse(json['shiftStartTime'] as String),
      shiftEndTime: DateTime.parse(json['shiftEndTime'] as String),
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      bookedAt: DateTime.parse(json['bookedAt'] as String),
      confirmedAt: json['confirmedAt'] != null 
          ? DateTime.parse(json['confirmedAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      notes: json['notes'] as String?,
      paymentInfo: json['paymentInfo'] != null 
          ? PaymentInfo.fromJson(json['paymentInfo'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shiftId': shiftId,
      'guardId': guardId,
      'guardName': guardName,
      'shiftTitle': shiftTitle,
      'locationName': locationName,
      'shiftStartTime': shiftStartTime.toIso8601String(),
      'shiftEndTime': shiftEndTime.toIso8601String(),
      'hourlyRate': hourlyRate,
      'status': status.name,
      'bookedAt': bookedAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'notes': notes,
      'paymentInfo': paymentInfo?.toJson(),
    };
  }

  Booking copyWith({
    String? id,
    String? shiftId,
    String? guardId,
    String? guardName,
    String? shiftTitle,
    String? locationName,
    DateTime? shiftStartTime,
    DateTime? shiftEndTime,
    double? hourlyRate,
    BookingStatus? status,
    DateTime? bookedAt,
    DateTime? confirmedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? notes,
    PaymentInfo? paymentInfo,
  }) {
    return Booking(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      shiftTitle: shiftTitle ?? this.shiftTitle,
      locationName: locationName ?? this.locationName,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      status: status ?? this.status,
      bookedAt: bookedAt ?? this.bookedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking(id: $id, shiftTitle: $shiftTitle, guardName: $guardName, status: $status)';
  }
}

enum BookingStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled'),
  noShow('No Show');

  const BookingStatus(this.displayName);
  final String displayName;
}

class PaymentInfo {
  final String id;
  final String bookingId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime? paidAt;
  final String? transactionId;
  final String? payrollPeriod;

  PaymentInfo({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.method,
    this.paidAt,
    this.transactionId,
    this.payrollPeriod,
  });

  bool get isPaid => status == PaymentStatus.paid;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (method) => method.name == json['method'],
        orElse: () => PaymentMethod.directDeposit,
      ),
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      transactionId: json['transactionId'] as String?,
      payrollPeriod: json['payrollPeriod'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'paidAt': paidAt?.toIso8601String(),
      'transactionId': transactionId,
      'payrollPeriod': payrollPeriod,
    };
  }

  PaymentInfo copyWith({
    String? id,
    String? bookingId,
    double? amount,
    PaymentStatus? status,
    PaymentMethod? method,
    DateTime? paidAt,
    String? transactionId,
    String? payrollPeriod,
  }) {
    return PaymentInfo(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      method: method ?? this.method,
      paidAt: paidAt ?? this.paidAt,
      transactionId: transactionId ?? this.transactionId,
      payrollPeriod: payrollPeriod ?? this.payrollPeriod,
    );
  }
}

enum PaymentStatus {
  pending('Pending'),
  processing('Processing'),
  paid('Paid'),
  failed('Failed'),
  cancelled('Cancelled');

  const PaymentStatus(this.displayName);
  final String displayName;
}

enum PaymentMethod {
  directDeposit('Direct Deposit'),
  check('Check'),
  cash('Cash'),
  paypal('PayPal'),
  other('Other');

  const PaymentMethod(this.displayName);
  final String displayName;
}

class BookingFilter {
  final BookingStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? locationId;
  final bool? upcomingOnly;

  BookingFilter({
    this.status,
    this.startDate,
    this.endDate,
    this.locationId,
    this.upcomingOnly,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status?.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'locationId': locationId,
      'upcomingOnly': upcomingOnly,
    };
  }

  BookingFilter copyWith({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? locationId,
    bool? upcomingOnly,
  }) {
    return BookingFilter(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      locationId: locationId ?? this.locationId,
      upcomingOnly: upcomingOnly ?? this.upcomingOnly,
    );
  }
}