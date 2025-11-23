import '../../core/repositories/base_repository.dart';
import '../../core/constants/database_constants.dart';
import '../../models/payroll.dart';

class PayrollRepository extends BaseRepository {
  static final PayrollRepository _instance = PayrollRepository._internal();
  static PayrollRepository get instance => _instance;
  PayrollRepository._internal();

  // Create payroll entry
  Future<String?> createPayrollEntry(PayrollEntry entry) async {
    try {
      final entryData = {
        DatabaseConstants.payrollId: entry.id,
        DatabaseConstants.payrollUserId: entry.userId,
        DatabaseConstants.payrollShiftId: entry.shiftId,
        DatabaseConstants.payrollShiftTitle: entry.shiftTitle,
        DatabaseConstants.payrollShiftDate: entry.shiftDate.toIso8601String(),
        DatabaseConstants.payrollStartTime: entry.startTime.toIso8601String(),
        DatabaseConstants.payrollEndTime: entry.endTime.toIso8601String(),
        DatabaseConstants.payrollHoursWorked: entry.hoursWorked,
        DatabaseConstants.payrollHourlyRate: entry.hourlyRate,
        DatabaseConstants.payrollTotalPay: entry.totalPay,
        DatabaseConstants.payrollStatus: entry.status.name,
        DatabaseConstants.payrollCreatedAt: entry.createdAt.toIso8601String(),
        DatabaseConstants.payrollConfirmedAt: entry.confirmedAt?.toIso8601String(),
        DatabaseConstants.payrollNotes: entry.notes,
      };

      await insert(DatabaseConstants.payrollEntriesTable, entryData);
      return entry.id;
    } catch (e) {
      print('Error creating payroll entry: $e');
      return null;
    }
  }

  // Get payroll entry by ID
  Future<PayrollEntry?> getPayrollEntryById(String entryId) async {
    try {
      final results = await query(
        DatabaseConstants.payrollEntriesTable,
        where: '${DatabaseConstants.payrollId} = ?',
        whereArgs: [entryId],
      );

      if (results.isEmpty) return null;

      final entryData = results.first;
      return _mapToPayrollEntry(entryData);
    } catch (e) {
      print('Error getting payroll entry by ID: $e');
      return null;
    }
  }

  // Get payroll entries for user
  Future<List<PayrollEntry>> getUserPayrollEntries(
    String userId, {
    int? year,
    int? month,
    PayrollStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String? whereClause = '${DatabaseConstants.payrollUserId} = ?';
      List<Object?> whereArgs = [userId];

      if (year != null && month != null) {
        // Filter by specific month and year
        final startDate = DateTime(year, month, 1);
        final endDate = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
        
        whereClause += ' AND ${DatabaseConstants.payrollShiftDate} >= ? AND ${DatabaseConstants.payrollShiftDate} <= ?';
        whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
      } else if (year != null) {
        // Filter by year only
        final startDate = DateTime(year, 1, 1);
        final endDate = DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));
        
        whereClause += ' AND ${DatabaseConstants.payrollShiftDate} >= ? AND ${DatabaseConstants.payrollShiftDate} <= ?';
        whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
      }

      if (status != null) {
        whereClause += ' AND ${DatabaseConstants.payrollStatus} = ?';
        whereArgs.add(status.name);
      }

      final results = await query(
        DatabaseConstants.payrollEntriesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: '${DatabaseConstants.payrollShiftDate} DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((entryData) => _mapToPayrollEntry(entryData)).toList();
    } catch (e) {
      print('Error getting user payroll entries: $e');
      return [];
    }
  }

  // Get monthly payroll summary
  Future<MonthlyPayroll?> getMonthlyPayroll(String userId, int year, int month) async {
    try {
      final entries = await getUserPayrollEntries(userId, year: year, month: month);
      
      if (entries.isEmpty) {
        return MonthlyPayroll.fromEntries(userId, year, month, []);
      }

      return MonthlyPayroll.fromEntries(userId, year, month, entries);
    } catch (e) {
      print('Error getting monthly payroll: $e');
      return null;
    }
  }

  // Update payroll entry
  Future<bool> updatePayrollEntry(PayrollEntry entry) async {
    try {
      final entryData = {
        DatabaseConstants.payrollShiftTitle: entry.shiftTitle,
        DatabaseConstants.payrollShiftDate: entry.shiftDate.toIso8601String(),
        DatabaseConstants.payrollStartTime: entry.startTime.toIso8601String(),
        DatabaseConstants.payrollEndTime: entry.endTime.toIso8601String(),
        DatabaseConstants.payrollHoursWorked: entry.hoursWorked,
        DatabaseConstants.payrollHourlyRate: entry.hourlyRate,
        DatabaseConstants.payrollTotalPay: entry.totalPay,
        DatabaseConstants.payrollStatus: entry.status.name,
        DatabaseConstants.payrollConfirmedAt: entry.confirmedAt?.toIso8601String(),
        DatabaseConstants.payrollNotes: entry.notes,
      };

      final result = await update(
        DatabaseConstants.payrollEntriesTable,
        entryData,
        where: '${DatabaseConstants.payrollId} = ?',
        whereArgs: [entry.id],
      );

      return result > 0;
    } catch (e) {
      print('Error updating payroll entry: $e');
      return false;
    }
  }

  // Confirm payroll entry
  Future<bool> confirmPayrollEntry(String entryId) async {
    try {
      final result = await update(
        DatabaseConstants.payrollEntriesTable,
        {
          DatabaseConstants.payrollStatus: PayrollStatus.confirmed.name,
          DatabaseConstants.payrollConfirmedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseConstants.payrollId} = ?',
        whereArgs: [entryId],
      );

      return result > 0;
    } catch (e) {
      print('Error confirming payroll entry: $e');
      return false;
    }
  }

  // Delete payroll entry
  Future<bool> deletePayrollEntry(String entryId) async {
    try {
      final result = await delete(
        DatabaseConstants.payrollEntriesTable,
        where: '${DatabaseConstants.payrollId} = ?',
        whereArgs: [entryId],
      );

      return result > 0;
    } catch (e) {
      print('Error deleting payroll entry: $e');
      return false;
    }
  }

  // Get payroll statistics
  Future<Map<String, dynamic>> getPayrollStatistics(String userId, {int? year}) async {
    try {
      String whereClause = '${DatabaseConstants.payrollUserId} = ?';
      List<Object?> whereArgs = [userId];

      if (year != null) {
        final startDate = DateTime(year, 1, 1);
        final endDate = DateTime(year + 1, 1, 1).subtract(const Duration(days: 1));
        
        whereClause += ' AND ${DatabaseConstants.payrollShiftDate} >= ? AND ${DatabaseConstants.payrollShiftDate} <= ?';
        whereArgs.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
      }

      final results = await rawQuery('''
        SELECT 
          COUNT(*) as total_shifts,
          SUM(${DatabaseConstants.payrollHoursWorked}) as total_hours,
          SUM(${DatabaseConstants.payrollTotalPay}) as total_earnings,
          COUNT(CASE WHEN ${DatabaseConstants.payrollStatus} = '${PayrollStatus.confirmed.name}' THEN 1 END) as confirmed_shifts,
          COUNT(CASE WHEN ${DatabaseConstants.payrollStatus} = '${PayrollStatus.pending.name}' THEN 1 END) as pending_shifts
        FROM ${DatabaseConstants.payrollEntriesTable}
        WHERE $whereClause
      ''', whereArgs);

      if (results.isNotEmpty) {
        final result = results.first;
        return {
          'totalShifts': result['total_shifts'] as int? ?? 0,
          'totalHours': (result['total_hours'] as num?)?.toDouble() ?? 0.0,
          'totalEarnings': (result['total_earnings'] as num?)?.toDouble() ?? 0.0,
          'confirmedShifts': result['confirmed_shifts'] as int? ?? 0,
          'pendingShifts': result['pending_shifts'] as int? ?? 0,
        };
      }

      return {
        'totalShifts': 0,
        'totalHours': 0.0,
        'totalEarnings': 0.0,
        'confirmedShifts': 0,
        'pendingShifts': 0,
      };
    } catch (e) {
      print('Error getting payroll statistics: $e');
      return {
        'totalShifts': 0,
        'totalHours': 0.0,
        'totalEarnings': 0.0,
        'confirmedShifts': 0,
        'pendingShifts': 0,
      };
    }
  }

  // Get all payroll entries for admin
  Future<List<PayrollEntry>> getAllPayrollEntries({
    PayrollStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String? whereClause;
      List<Object?> whereArgs = [];

      List<String> conditions = [];

      if (status != null) {
        conditions.add('${DatabaseConstants.payrollStatus} = ?');
        whereArgs.add(status.name);
      }

      if (startDate != null) {
        conditions.add('${DatabaseConstants.payrollShiftDate} >= ?');
        whereArgs.add(startDate.toIso8601String());
      }

      if (endDate != null) {
        conditions.add('${DatabaseConstants.payrollShiftDate} <= ?');
        whereArgs.add(endDate.toIso8601String());
      }

      if (conditions.isNotEmpty) {
        whereClause = conditions.join(' AND ');
      }

      final results = await query(
        DatabaseConstants.payrollEntriesTable,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '${DatabaseConstants.payrollShiftDate} DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((entryData) => _mapToPayrollEntry(entryData)).toList();
    } catch (e) {
      print('Error getting all payroll entries: $e');
      return [];
    }
  }

  // Helper method to map database result to PayrollEntry
  PayrollEntry _mapToPayrollEntry(Map<String, dynamic> entryData) {
    return PayrollEntry(
      id: entryData[DatabaseConstants.payrollId] as String,
      userId: entryData[DatabaseConstants.payrollUserId] as String,
      shiftId: entryData[DatabaseConstants.payrollShiftId] as String,
      shiftTitle: entryData[DatabaseConstants.payrollShiftTitle] as String,
      shiftDate: DateTime.parse(entryData[DatabaseConstants.payrollShiftDate] as String),
      startTime: DateTime.parse(entryData[DatabaseConstants.payrollStartTime] as String),
      endTime: DateTime.parse(entryData[DatabaseConstants.payrollEndTime] as String),
      hoursWorked: (entryData[DatabaseConstants.payrollHoursWorked] as num).toDouble(),
      hourlyRate: (entryData[DatabaseConstants.payrollHourlyRate] as num).toDouble(),
      totalPay: (entryData[DatabaseConstants.payrollTotalPay] as num).toDouble(),
      status: PayrollStatus.values.firstWhere(
        (status) => status.name == entryData[DatabaseConstants.payrollStatus],
        orElse: () => PayrollStatus.pending,
      ),
      createdAt: DateTime.parse(entryData[DatabaseConstants.payrollCreatedAt] as String),
      confirmedAt: entryData[DatabaseConstants.payrollConfirmedAt] != null
          ? DateTime.parse(entryData[DatabaseConstants.payrollConfirmedAt] as String)
          : null,
      notes: entryData[DatabaseConstants.payrollNotes] as String?,
    );
  }
}
