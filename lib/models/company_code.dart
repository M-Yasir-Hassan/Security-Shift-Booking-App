class CompanyCode {
  final String id;
  final String code;
  final String companyName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String createdBy; // Secondary Admin ID
  final int maxUses;
  final int currentUses;

  CompanyCode({
    required this.id,
    required this.code,
    required this.companyName,
    this.isActive = true,
    required this.createdAt,
    this.expiresAt,
    required this.createdBy,
    this.maxUses = 100,
    this.currentUses = 0,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUsable => isActive && !isExpired && currentUses < maxUses;

  factory CompanyCode.fromJson(Map<String, dynamic> json) {
    return CompanyCode(
      id: json['id'] as String,
      code: json['code'] as String,
      companyName: json['companyName'] as String,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String) 
          : null,
      createdBy: json['createdBy'] as String,
      maxUses: json['maxUses'] as int? ?? 100,
      currentUses: json['currentUses'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'companyName': companyName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
      'maxUses': maxUses,
      'currentUses': currentUses,
    };
  }

  CompanyCode copyWith({
    String? id,
    String? code,
    String? companyName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? createdBy,
    int? maxUses,
    int? currentUses,
  }) {
    return CompanyCode(
      id: id ?? this.id,
      code: code ?? this.code,
      companyName: companyName ?? this.companyName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyCode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CompanyCode(id: $id, code: $code, companyName: $companyName, isActive: $isActive)';
  }
}
