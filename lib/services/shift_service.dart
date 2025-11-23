import '../models/shift.dart';
import '../models/user.dart';
import '../data/repositories/shift_repository.dart';
import 'auth_service.dart';

class ShiftService {
  static final ShiftService _instance = ShiftService._internal();
  static ShiftService get instance => _instance;
  ShiftService._internal();

  final AuthService _authService = AuthService.instance;
  final ShiftRepository _shiftRepository = ShiftRepository.instance;

  /// Get all available shifts with role-based filtering
  Future<ShiftResult> getShifts({
    ShiftStatus? status,
    ShiftType? shiftType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isUrgent,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      
      // Get shifts from repository
      List<Shift> shifts = await _shiftRepository.getShifts(
        status: status ?? ShiftStatus.open,
        shiftType: shiftType,
        startDate: startDate,
        endDate: endDate,
        isUrgent: isUrgent,
        limit: limit,
        offset: offset,
      );

      // Apply role-based filtering
      if (currentUser != null) {
        shifts = _applyRoleBasedFiltering(shifts, currentUser.userType);
      }

      return ShiftResult.success(
        shifts: shifts,
        totalCount: shifts.length,
        currentPage: (offset ~/ limit) + 1,
        totalPages: ((shifts.length + limit - 1) ~/ limit),
      );
    } catch (e) {
      return ShiftResult.failure(
        message: 'Failed to fetch shifts: ${e.toString()}',
      );
    }
  }

  /// Get shifts with role-based filtering (for demo purposes)
  Future<ShiftResult> getShiftsWithRoleFiltering({
    ShiftStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return await getShifts(
      status: status,
      limit: limit,
      offset: (page - 1) * limit,
    );
  }

  /// Get shifts assigned to current user
  Future<ShiftResult> getMyShifts({
    ShiftStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ShiftResult.failure(message: 'User not authenticated');
      }

      final shifts = await _shiftRepository.getUserShifts(
        currentUser.id,
        status: status,
        limit: limit,
        offset: (page - 1) * limit,
      );

      return ShiftResult.success(
        shifts: shifts,
        totalCount: shifts.length,
        currentPage: page,
        totalPages: ((shifts.length + limit - 1) ~/ limit),
      );
    } catch (e) {
      return ShiftResult.failure(
        message: 'Failed to fetch user shifts: ${e.toString()}',
      );
    }
  }

  /// Create a new shift
  Future<ShiftResult> createShift(Shift shift) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ShiftResult.failure(message: 'User not authenticated');
      }

      // Check if user has permission to create shifts
      if (!_canCreateShifts(currentUser.userType)) {
        return ShiftResult.failure(message: 'Insufficient permissions to create shifts');
      }

      final shiftId = await _shiftRepository.createShift(shift);
      if (shiftId != null) {
        final createdShift = await _shiftRepository.getShiftById(shiftId);
        return ShiftResult.success(
          shifts: createdShift != null ? [createdShift] : [],
          totalCount: 1,
          currentPage: 1,
          totalPages: 1,
        );
      } else {
        return ShiftResult.failure(message: 'Failed to create shift');
      }
    } catch (e) {
      return ShiftResult.failure(
        message: 'Failed to create shift: ${e.toString()}',
      );
    }
  }

  /// Update an existing shift
  Future<ShiftResult> updateShift(Shift shift) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return ShiftResult.failure(message: 'User not authenticated');
      }

      // Check if user has permission to update shifts
      if (!_canUpdateShifts(currentUser.userType)) {
        return ShiftResult.failure(message: 'Insufficient permissions to update shifts');
      }

      final success = await _shiftRepository.updateShift(shift);
      if (success) {
        final updatedShift = await _shiftRepository.getShiftById(shift.id);
        return ShiftResult.success(
          shifts: updatedShift != null ? [updatedShift] : [],
          totalCount: 1,
          currentPage: 1,
          totalPages: 1,
        );
      } else {
        return ShiftResult.failure(message: 'Failed to update shift');
      }
    } catch (e) {
      return ShiftResult.failure(
        message: 'Failed to update shift: ${e.toString()}',
      );
    }
  }

  /// Apply for a shift
  Future<bool> applyForShift(String shiftId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Check if user can apply for shifts
      if (!_canApplyForShifts(currentUser.userType)) return false;

      return await _shiftRepository.assignUserToShift(
        shiftId,
        currentUser.id,
        currentUser.fullName,
      );
    } catch (e) {
      print('Error applying for shift: $e');
      return false;
    }
  }

  /// Cancel shift application
  Future<bool> cancelShiftApplication(String shiftId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      return await _shiftRepository.removeUserFromShift(shiftId, currentUser.id);
    } catch (e) {
      print('Error canceling shift application: $e');
      return false;
    }
  }

  /// Delete a shift
  Future<bool> deleteShift(String shiftId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Check if user has permission to delete shifts
      if (!_canDeleteShifts(currentUser.userType)) return false;

      return await _shiftRepository.deleteShift(shiftId);
    } catch (e) {
      print('Error deleting shift: $e');
      return false;
    }
  }

  /// Search shifts
  Future<ShiftResult> searchShifts(String searchTerm, {int limit = 20}) async {
    try {
      final currentUser = _authService.currentUser;
      
      List<Shift> shifts = await _shiftRepository.searchShifts(searchTerm, limit: limit);

      // Apply role-based filtering
      if (currentUser != null) {
        shifts = _applyRoleBasedFiltering(shifts, currentUser.userType);
      }

      return ShiftResult.success(
        shifts: shifts,
        totalCount: shifts.length,
        currentPage: 1,
        totalPages: 1,
      );
    } catch (e) {
      return ShiftResult.failure(
        message: 'Failed to search shifts: ${e.toString()}',
      );
    }
  }

  /// Apply role-based filtering to shifts
  List<Shift> _applyRoleBasedFiltering(List<Shift> shifts, UserType userType) {
    switch (userType) {
      case UserType.steward:
        // Stewards can only see steward shifts
        return shifts.where((shift) => shift.shiftType == ShiftType.stewardShift).toList();
      
      case UserType.siasteward:
        // SIA Stewards can see steward, SIA, emergency, and event shifts
        return shifts.where((shift) => 
          shift.shiftType == ShiftType.stewardShift ||
          shift.shiftType == ShiftType.siaShift ||
          shift.shiftType == ShiftType.emergency ||
          shift.shiftType == ShiftType.event
        ).toList();
      
      case UserType.manager:
      case UserType.secondaryAdmin:
      case UserType.seniorAdmin:
        // Managers and admins can see all shifts
        return shifts;
    }
  }

  /// Check if user can create shifts
  bool _canCreateShifts(UserType userType) {
    return userType == UserType.manager ||
           userType == UserType.secondaryAdmin ||
           userType == UserType.seniorAdmin;
  }

  /// Check if user can update shifts
  bool _canUpdateShifts(UserType userType) {
    return userType == UserType.manager ||
           userType == UserType.secondaryAdmin ||
           userType == UserType.seniorAdmin;
  }

  /// Check if user can delete shifts
  bool _canDeleteShifts(UserType userType) {
    return userType == UserType.secondaryAdmin ||
           userType == UserType.seniorAdmin;
  }

  /// Check if user can apply for shifts
  bool _canApplyForShifts(UserType userType) {
    return userType == UserType.steward ||
           userType == UserType.siasteward;
  }
}

/// Result class for shift operations
class ShiftResult {
  final bool success;
  final List<Shift>? shifts;
  final String? message;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  ShiftResult._({
    required this.success,
    this.shifts,
    this.message,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory ShiftResult.success({
    required List<Shift> shifts,
    required int totalCount,
    required int currentPage,
    required int totalPages,
  }) {
    return ShiftResult._(
      success: true,
      shifts: shifts,
      totalCount: totalCount,
      currentPage: currentPage,
      totalPages: totalPages,
    );
  }

  factory ShiftResult.failure({required String message}) {
    return ShiftResult._(
      success: false,
      message: message,
    );
  }
}
