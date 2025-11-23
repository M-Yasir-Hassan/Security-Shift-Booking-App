import 'package:flutter/material.dart';
import '../../models/payroll.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../data/repositories/payroll_repository.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final AuthService _authService = AuthService.instance;
  final PayrollRepository _payrollRepository = PayrollRepository.instance;
  
  User? _currentUser;
  MonthlyPayroll? _currentMonthPayroll;
  List<MonthlyPayroll> _payrollHistory = [];
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadPayrollData();
  }

  Future<void> _loadPayrollData() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUser = _authService.currentUser;
      
      if (_currentUser != null) {
        // Load real payroll data from database
        await _loadPayrollFromDatabase();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payroll data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPayrollFromDatabase() async {
    if (_currentUser == null) return;

    try {
      // Get current month payroll
      _currentMonthPayroll = await _payrollRepository.getMonthlyPayroll(
        _currentUser!.id,
        _selectedYear,
        _selectedMonth,
      );

      // Get previous months payroll (last 3 months)
      _payrollHistory = [];
      for (int i = 1; i <= 3; i++) {
        int month = _selectedMonth - i;
        int year = _selectedYear;
        
        if (month <= 0) {
          month += 12;
          year -= 1;
        }
        
        final monthlyPayroll = await _payrollRepository.getMonthlyPayroll(
          _currentUser!.id,
          year,
          month,
        );
        
        if (monthlyPayroll != null && monthlyPayroll.entries.isNotEmpty) {
          _payrollHistory.add(monthlyPayroll);
        }
      }
    } catch (e) {
      print('Error loading payroll data: $e');
      // Create empty payroll if error occurs
      _currentMonthPayroll = MonthlyPayroll.fromEntries(
        _currentUser!.id,
        _selectedYear,
        _selectedMonth,
        [],
      );
    }
  }

  void _selectMonth() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= 12; i++)
                  ListTile(
                    title: Text(_getMonthName(i)),
                    onTap: () {
                      setState(() {
                        _selectedMonth = i;
                      });
                      Navigator.pop(context);
                      _loadPayrollData();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Header
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '${_getMonthName(_selectedMonth)} $_selectedYear',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_currentMonthPayroll != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Hours',
                                    '${_currentMonthPayroll!.totalHours.toStringAsFixed(1)}h',
                                    Icons.access_time,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Total Earnings',
                                    '£${_currentMonthPayroll!.totalEarnings.toStringAsFixed(2)}',
                                    Icons.attach_money,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Confirmed',
                                    '${_currentMonthPayroll!.confirmedShifts} shifts',
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildSummaryCard(
                                    'Pending',
                                    '${_currentMonthPayroll!.pendingShifts} shifts',
                                    Icons.pending,
                                    Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Shift Details
                  Text(
                    'Shift Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_currentMonthPayroll?.entries.isEmpty ?? true)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No shifts worked this month',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_currentMonthPayroll!.entries.map((entry) => _buildPayrollEntryCard(entry))),

                  const SizedBox(height: 24),

                  // Previous Months
                  if (_payrollHistory.isNotEmpty) ...[
                    Text(
                      'Previous Months',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_payrollHistory.map((payroll) => _buildMonthlyPayrollCard(payroll))),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollEntryCard(PayrollEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.shiftTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(entry.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(entry.status)),
                  ),
                  child: Text(
                    entry.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(entry.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDate(entry.shiftDate)} • ${_formatTime(entry.startTime)} - ${_formatTime(entry.endTime)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    '${entry.hoursWorked.toStringAsFixed(1)} hours',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    '£${entry.hourlyRate.toStringAsFixed(2)}/hr',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    '£${entry.totalPay.toStringAsFixed(2)}',
                    Icons.payment,
                    const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPayrollCard(MonthlyPayroll payroll) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${payroll.monthName} ${payroll.year}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    '${payroll.totalHours.toStringAsFixed(1)}h',
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    '£${payroll.totalEarnings.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    '${payroll.entries.length} shifts',
                    Icons.work,
                    const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PayrollStatus status) {
    switch (status) {
      case PayrollStatus.pending:
        return Colors.orange;
      case PayrollStatus.confirmed:
        return Colors.green;
      case PayrollStatus.paid:
        return const Color(0xFF1565C0);
      case PayrollStatus.disputed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
