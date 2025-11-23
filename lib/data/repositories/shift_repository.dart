import 'dart:convert';
import '../../core/repositories/base_repository.dart';
import '../../core/constants/database_constants.dart';
import '../../models/shift.dart';

class ShiftRepository extends BaseRepository {
  static final ShiftRepository _instance = ShiftRepository._internal();
  static ShiftRepository get instance => _instance;
  ShiftRepository._internal();

  // Create shift
  Future<String?> createShift(Shift shift) async {
    try {
      final shiftData = {
        DatabaseConstants.shiftId: shift.id,
        DatabaseConstants.shiftTitle: shift.title,
        DatabaseConstants.shiftDescription: shift.description,
        DatabaseConstants.shiftLocationId: shift.locationId,
        DatabaseConstants.shiftLocationName: shift.locationName,
        DatabaseConstants.shiftLocationAddress: shift.locationAddress,
        DatabaseConstants.shiftStartTime: shift.startTime.toIso8601String(),
        DatabaseConstants.shiftEndTime: shift.endTime.toIso8601String(),
        DatabaseConstants.shiftHourlyRate: shift.hourlyRate,
        DatabaseConstants.shiftRequiredGuards: shift.requiredGuards,
        DatabaseConstants.shiftAssignedGuards: shift.assignedGuards,
        DatabaseConstants.shiftRequiredSiaGuards: shift.requiredSiaGuards,
        DatabaseConstants.shiftRequiredStewardGuards: shift.requiredStewardGuards,
        DatabaseConstants.shiftStatus: shift.status.name,
        DatabaseConstants.shiftType: shift.shiftType.name,
        DatabaseConstants.shiftCreatedBy: shift.createdBy,
        DatabaseConstants.shiftCreatedAt: shift.createdAt.toIso8601String(),
        DatabaseConstants.shiftUpdatedAt: shift.updatedAt.toIso8601String(),
        DatabaseConstants.shiftRequiredCertifications: jsonEncode(shift.requiredCertifications),
        DatabaseConstants.shiftSpecialInstructions: shift.specialInstructions,
        DatabaseConstants.shiftUniformRequirements: shift.uniformRequirements,
        DatabaseConstants.shiftIsUrgent: shift.isUrgent ? 1 : 0,
      };

      await insert(DatabaseConstants.shiftsTable, shiftData);

      // Insert shift assignments if any
      for (final assignment in shift.assignments) {
        final assignmentData = {
          DatabaseConstants.assignmentId: assignment.id,
          DatabaseConstants.assignmentShiftId: shift.id,
          DatabaseConstants.assignmentUserId: assignment.guardId,
          DatabaseConstants.assignmentUserName: assignment.guardName,
          DatabaseConstants.assignmentStatus: assignment.status.name,
          DatabaseConstants.assignmentAssignedAt: assignment.assignedAt.toIso8601String(),
          DatabaseConstants.assignmentNotes: assignment.notes,
        };

        await insert(DatabaseConstants.shiftAssignmentsTable, assignmentData);
      }

      return shift.id;
    } catch (e) {
      print('Error creating shift: $e');
      return null;
    }
  }

  // Get shift by ID
  Future<Shift?> getShiftById(String shiftId) async {
    try {
      final shiftResults = await query(
        DatabaseConstants.shiftsTable,
        where: '${DatabaseConstants.shiftId} = ?',
        whereArgs: [shiftId],
      );

      if (shiftResults.isEmpty) return null;

      final shiftData = shiftResults.first;

      // Get shift assignments
      final assignmentResults = await query(
        DatabaseConstants.shiftAssignmentsTable,
        where: '${DatabaseConstants.assignmentShiftId} = ?',
        whereArgs: [shiftId],
      );

      final assignments = assignmentResults.map((assignmentData) {
        return ShiftAssignment(
          id: assignmentData[DatabaseConstants.assignmentId] as String,
          shiftId: shiftId,
          guardId: assignmentData[DatabaseConstants.assignmentUserId] as String,
          guardName: assignmentData[DatabaseConstants.assignmentUserName] as String,
          status: AssignmentStatus.values.firstWhere(
            (status) => status.name == assignmentData[DatabaseConstants.assignmentStatus],
            orElse: () => AssignmentStatus.assigned,
          ),
          assignedAt: DateTime.parse(assignmentData[DatabaseConstants.assignmentAssignedAt] as String),
          notes: assignmentData[DatabaseConstants.assignmentNotes] as String?,
        );
      }).toList();

      return Shift(
        id: shiftData[DatabaseConstants.shiftId] as String,
        title: shiftData[DatabaseConstants.shiftTitle] as String,
        description: shiftData[DatabaseConstants.shiftDescription] as String,
        locationId: shiftData[DatabaseConstants.shiftLocationId] as String,
        locationName: shiftData[DatabaseConstants.shiftLocationName] as String,
        locationAddress: shiftData[DatabaseConstants.shiftLocationAddress] as String,
        startTime: DateTime.parse(shiftData[DatabaseConstants.shiftStartTime] as String),
        endTime: DateTime.parse(shiftData[DatabaseConstants.shiftEndTime] as String),
        hourlyRate: (shiftData[DatabaseConstants.shiftHourlyRate] as num).toDouble(),
        requiredGuards: shiftData[DatabaseConstants.shiftRequiredGuards] as int,
        assignedGuards: shiftData[DatabaseConstants.shiftAssignedGuards] as int,
        status: ShiftStatus.values.firstWhere(
          (status) => status.name == shiftData[DatabaseConstants.shiftStatus],
          orElse: () => ShiftStatus.open,
        ),
        shiftType: ShiftType.values.firstWhere(
          (type) => type.name == shiftData[DatabaseConstants.shiftType],
          orElse: () => ShiftType.stewardShift,
        ),
        createdBy: shiftData[DatabaseConstants.shiftCreatedBy] as String,
        createdAt: DateTime.parse(shiftData[DatabaseConstants.shiftCreatedAt] as String),
        updatedAt: DateTime.parse(shiftData[DatabaseConstants.shiftUpdatedAt] as String),
        requiredCertifications: shiftData[DatabaseConstants.shiftRequiredCertifications] != null
            ? List<String>.from(jsonDecode(shiftData[DatabaseConstants.shiftRequiredCertifications] as String))
            : [],
        specialInstructions: shiftData[DatabaseConstants.shiftSpecialInstructions] as String?,
        uniformRequirements: shiftData[DatabaseConstants.shiftUniformRequirements] as String?,
        isUrgent: (shiftData[DatabaseConstants.shiftIsUrgent] as int) == 1,
        assignments: assignments,
      );
    } catch (e) {
      print('Error getting shift by ID: $e');
      return null;
    }
  }

  // Get shifts with filters
  Future<List<Shift>> getShifts({
    ShiftStatus? status,
    ShiftType? shiftType,
    String? createdBy,
    DateTime? startDate,
    DateTime? endDate,
    bool? isUrgent,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String? whereClause;
      List<Object?> whereArgs = [];

      List<String> conditions = [];

      if (status != null) {
        conditions.add('${DatabaseConstants.shiftStatus} = ?');
        whereArgs.add(status.name);
      }

      if (shiftType != null) {
        conditions.add('${DatabaseConstants.shiftType} = ?');
        whereArgs.add(shiftType.name);
      }

      if (createdBy != null) {
        conditions.add('${DatabaseConstants.shiftCreatedBy} = ?');
        whereArgs.add(createdBy);
      }

      if (startDate != null) {
        conditions.add('${DatabaseConstants.shiftStartTime} >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        conditions.add('${DatabaseConstants.shiftEndTime} <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (isUrgent != null) {
        conditions.add('${DatabaseConstants.shiftIsUrgent} = ?');
        whereArgs.add(isUrgent ? 1 : 0);
      }

      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
      }

      final results = await query(
        DatabaseConstants.shiftsTable,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '${DatabaseConstants.shiftStartTime} ASC',
        limit: limit,
        offset: offset,
      );

      final shifts = <Shift>[];
      for (final shiftData in results) {
        final shiftId = shiftData[DatabaseConstants.shiftId] as String;
        final shift = await getShiftById(shiftId);
        if (shift != null) {
          shifts.add(shift);
        }
      }

      return shifts;
    } catch (e) {
      print('Error getting shifts: $e');
      return [];
    }
  }

  // Get shifts for user (assigned shifts)
  Future<List<Shift>> getUserShifts(String userId, {
    ShiftStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      String whereClause = '${DatabaseConstants.assignmentUserId} = ?';
      List<Object?> whereArgs = [userId];

      if (status != null) {
        whereClause += ' AND s.${DatabaseConstants.shiftStatus} = ?';
        whereArgs.add(status.name);
      }

      final results = await rawQuery('''
        SELECT DISTINCT s.${DatabaseConstants.shiftId}
        FROM ${DatabaseConstants.shiftAssignmentsTable} sa
        JOIN ${DatabaseConstants.shiftsTable} s ON sa.${DatabaseConstants.assignmentShiftId} = s.${DatabaseConstants.shiftId}
        WHERE $whereClause
        ORDER BY s.${DatabaseConstants.shiftStartTime} ASC
        LIMIT ? OFFSET ?
      ''', [...whereArgs, limit, offset]);

      final shifts = <Shift>[];
      for (final result in results) {
        final shiftId = result[DatabaseConstants.shiftId] as String;
        final shift = await getShiftById(shiftId);
        if (shift != null) {
          shifts.add(shift);
        }
      }

      return shifts;
    } catch (e) {
      print('Error getting user shifts: $e');
      return [];
    }
  }

  // Update shift
  Future<bool> updateShift(Shift shift) async {
    try {
      final shiftData = {
        DatabaseConstants.shiftTitle: shift.title,
        DatabaseConstants.shiftDescription: shift.description,
        DatabaseConstants.shiftLocationId: shift.locationId,
        DatabaseConstants.shiftLocationName: shift.locationName,
        DatabaseConstants.shiftLocationAddress: shift.locationAddress,
        DatabaseConstants.shiftStartTime: shift.startTime.toIso8601String(),
        DatabaseConstants.shiftEndTime: shift.endTime.toIso8601String(),
        DatabaseConstants.shiftHourlyRate: shift.hourlyRate,
        DatabaseConstants.shiftRequiredGuards: shift.requiredGuards,
        DatabaseConstants.shiftAssignedGuards: shift.assignedGuards,
        DatabaseConstants.shiftRequiredSiaGuards: shift.requiredSiaGuards,
        DatabaseConstants.shiftRequiredStewardGuards: shift.requiredStewardGuards,
        DatabaseConstants.shiftStatus: shift.status.name,
        DatabaseConstants.shiftType: shift.shiftType.name,
        DatabaseConstants.shiftUpdatedAt: DateTime.now().toIso8601String(),
        DatabaseConstants.shiftRequiredCertifications: jsonEncode(shift.requiredCertifications),
        DatabaseConstants.shiftSpecialInstructions: shift.specialInstructions,
        DatabaseConstants.shiftUniformRequirements: shift.uniformRequirements,
        DatabaseConstants.shiftIsUrgent: shift.isUrgent ? 1 : 0,
      };

      final result = await update(
        DatabaseConstants.shiftsTable,
        shiftData,
        where: '${DatabaseConstants.shiftId} = ?',
        whereArgs: [shift.id],
      );

      return result > 0;
    } catch (e) {
      print('Error updating shift: $e');
      return false;
    }
  }

  // Delete shift
  Future<bool> deleteShift(String shiftId) async {
    try {
      return await transaction((txn) async {
        // Delete shift assignments first
        await txn.delete(
          DatabaseConstants.shiftAssignmentsTable,
          where: '${DatabaseConstants.assignmentShiftId} = ?',
          whereArgs: [shiftId],
        );

        // Delete shift
        final result = await txn.delete(
          DatabaseConstants.shiftsTable,
          where: '${DatabaseConstants.shiftId} = ?',
          whereArgs: [shiftId],
        );

        return result > 0;
      });
    } catch (e) {
      print('Error deleting shift: $e');
      return false;
    }
  }

  // Assign user to shift
  Future<bool> assignUserToShift(String shiftId, String userId, String userName) async {
    try {
      return await transaction((txn) async {
        // Check if user is already assigned
        final existingAssignments = await txn.query(
          DatabaseConstants.shiftAssignmentsTable,
          where: '${DatabaseConstants.assignmentShiftId} = ? AND ${DatabaseConstants.assignmentUserId} = ?',
          whereArgs: [shiftId, userId],
        );

        if (existingAssignments.isNotEmpty) {
          return false; // User already assigned
        }

        // Create assignment
        final assignmentData = {
          DatabaseConstants.assignmentId: 'assignment_${DateTime.now().millisecondsSinceEpoch}',
          DatabaseConstants.assignmentShiftId: shiftId,
          DatabaseConstants.assignmentUserId: userId,
          DatabaseConstants.assignmentUserName: userName,
          DatabaseConstants.assignmentStatus: AssignmentStatus.assigned.name,
          DatabaseConstants.assignmentAssignedAt: DateTime.now().toIso8601String(),
        };

        await txn.insert(DatabaseConstants.shiftAssignmentsTable, assignmentData);

        // Get shift details to check if it should be marked as filled
        final shiftResults = await txn.query(
          DatabaseConstants.shiftsTable,
          where: '${DatabaseConstants.shiftId} = ?',
          whereArgs: [shiftId],
        );

        if (shiftResults.isNotEmpty) {
          final shift = shiftResults.first;
          final currentAssigned = (shift[DatabaseConstants.shiftAssignedGuards] as int? ?? 0);
          final requiredGuards = (shift[DatabaseConstants.shiftRequiredGuards] as int? ?? 1);
          final newAssignedCount = currentAssigned + 1;
          
          // Determine new status
          String newStatus;
          if (newAssignedCount >= requiredGuards) {
            newStatus = ShiftStatus.active.name; // Shift is now filled/active
          } else {
            newStatus = ShiftStatus.open.name; // Still needs more guards
          }

          // Update assigned guards count and status
          await txn.rawUpdate('''
            UPDATE ${DatabaseConstants.shiftsTable} 
            SET ${DatabaseConstants.shiftAssignedGuards} = ?,
                ${DatabaseConstants.shiftStatus} = ?,
                ${DatabaseConstants.shiftUpdatedAt} = ?
            WHERE ${DatabaseConstants.shiftId} = ?
          ''', [newAssignedCount, newStatus, DateTime.now().toIso8601String(), shiftId]);
          
          print('🎯 SHIFT: Updated shift $shiftId - Assigned: $newAssignedCount/$requiredGuards, Status: $newStatus');
        }

        return true;
      });
    } catch (e) {
      print('Error assigning user to shift: $e');
      return false;
    }
  }

  // Remove user from shift
  Future<bool> removeUserFromShift(String shiftId, String userId) async {
    try {
      return await transaction((txn) async {
        // Delete assignment
        final result = await txn.delete(
          DatabaseConstants.shiftAssignmentsTable,
          where: '${DatabaseConstants.assignmentShiftId} = ? AND ${DatabaseConstants.assignmentUserId} = ?',
          whereArgs: [shiftId, userId],
        );

        if (result > 0) {
          // Get shift details to update status
          final shiftResults = await txn.query(
            DatabaseConstants.shiftsTable,
            where: '${DatabaseConstants.shiftId} = ?',
            whereArgs: [shiftId],
          );

          if (shiftResults.isNotEmpty) {
            final shift = shiftResults.first;
            final currentAssigned = (shift[DatabaseConstants.shiftAssignedGuards] as int? ?? 0);
            final requiredGuards = (shift[DatabaseConstants.shiftRequiredGuards] as int? ?? 1);
            final newAssignedCount = (currentAssigned - 1).clamp(0, requiredGuards);
            
            // Determine new status
            String newStatus;
            if (newAssignedCount >= requiredGuards) {
              newStatus = ShiftStatus.active.name; // Still filled
            } else {
              newStatus = ShiftStatus.open.name; // Now has openings
            }

            // Update assigned guards count and status
            await txn.rawUpdate('''
              UPDATE ${DatabaseConstants.shiftsTable} 
              SET ${DatabaseConstants.shiftAssignedGuards} = ?,
                  ${DatabaseConstants.shiftStatus} = ?,
                  ${DatabaseConstants.shiftUpdatedAt} = ?
              WHERE ${DatabaseConstants.shiftId} = ?
            ''', [newAssignedCount, newStatus, DateTime.now().toIso8601String(), shiftId]);
            
            print('🎯 SHIFT: Removed user from shift $shiftId - Assigned: $newAssignedCount/$requiredGuards, Status: $newStatus');
          }
        }

        return result > 0;
      });
    } catch (e) {
      print('Error removing user from shift: $e');
      return false;
    }
  }

  // Search shifts
  Future<List<Shift>> searchShifts(String searchTerm, {int limit = 20}) async {
    try {
      final results = await query(
        DatabaseConstants.shiftsTable,
        where: '''
          ${DatabaseConstants.shiftTitle} LIKE ? OR 
          ${DatabaseConstants.shiftDescription} LIKE ? OR 
          ${DatabaseConstants.shiftLocationName} LIKE ? OR
          ${DatabaseConstants.shiftLocationAddress} LIKE ?
        ''',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: '${DatabaseConstants.shiftStartTime} ASC',
        limit: limit,
      );

      final shifts = <Shift>[];
      for (final shiftData in results) {
        final shiftId = shiftData[DatabaseConstants.shiftId] as String;
        final shift = await getShiftById(shiftId);
        if (shift != null) {
          shifts.add(shift);
        }
      }

      return shifts;
    } catch (e) {
      print('Error searching shifts: $e');
      return [];
    }
  }
}
