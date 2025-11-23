import 'package:flutter/material.dart';
import '../../models/shift.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/shift_service.dart';
import '../../services/local_storage_service.dart';
import 'shift_details_screen.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService.instance;
  final ShiftService _shiftService = ShiftService.instance;
  final LocalStorageService _localStorageService = LocalStorageService.instance;
  
  late TabController _tabController;
  List<Shift> _allShifts = [];
  List<Shift> _myShifts = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    try {
      setState(() => _isLoading = true);
      
      _currentUser = _authService.currentUser;
      
      if (_currentUser != null) {
        // Load all available shifts with role-based filtering
        final allShiftsResult = await _shiftService.getShiftsWithRoleFiltering();
        
        // Load user's shifts
        final myShiftsResult = await _shiftService.getMyShifts();
        
        setState(() {
           if (allShiftsResult.success && allShiftsResult.shifts != null) {
             _allShifts = allShiftsResult.shifts!;
           }
           if (myShiftsResult.success && myShiftsResult.shifts != null) {
             _myShifts = myShiftsResult.shifts!;
           }
         });
      } else {
        // Try to load from local storage
        final cachedShifts = await _localStorageService.getCachedShifts();
        setState(() {
          _allShifts = cachedShifts;
          _myShifts = [];
        });
      }
    } catch (e) {
      // Fallback to local storage
      final cachedShifts = await _localStorageService.getCachedShifts();
      setState(() {
        _allShifts = cachedShifts;
        _myShifts = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading shifts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyForShift(Shift shift) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to apply for shifts')),
      );
      return;
    }

    try {
      final success = await _shiftService.applyForShift(shift.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully')),
        );
        _loadShifts(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error applying for shift: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shifts'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Available Shifts'),
            Tab(text: 'My Shifts'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableShifts(),
                _buildMyShifts(),
              ],
            ),
      floatingActionButton: (_currentUser?.userType == UserType.steward || 
                            _currentUser?.userType == UserType.siasteward)
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement create shift functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Create shift coming soon')),
                );
              },
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAvailableShifts() {
    final availableShifts = _allShifts.where((shift) => 
        shift.status == ShiftStatus.open && 
        !shift.isFullyStaffed
    ).toList();

    if (availableShifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No available shifts',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShifts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: availableShifts.length,
        itemBuilder: (context, index) {
          final shift = availableShifts[index];
          return _buildShiftCard(shift, isAvailable: true);
        },
      ),
    );
  }

  Widget _buildMyShifts() {
    if (_myShifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No shifts assigned',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShifts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myShifts.length,
        itemBuilder: (context, index) {
          final shift = _myShifts[index];
          return _buildShiftCard(shift, isAvailable: false);
        },
      ),
    );
  }

  Widget _buildShiftCard(Shift shift, {required bool isAvailable}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShiftDetailsScreen(shift: shift),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    shift.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(shift.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(shift.status)),
                  ),
                  child: Text(
                    shift.status.displayName,
                    style: TextStyle(
                      color: _getStatusColor(shift.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              shift.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Location and Time
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shift.locationName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDateTime(shift.startTime)} - ${_formatDateTime(shift.endTime)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Rate and Duration
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${shift.hourlyRate.toStringAsFixed(2)}/hr',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${shift.duration.inHours}h ${shift.duration.inMinutes % 60}m',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  'Total: \$${shift.totalPay.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Guards Info
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: shift.isFullyStaffed ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${shift.assignedGuards}/${shift.requiredGuards} guards',
                  style: TextStyle(
                    color: shift.isFullyStaffed ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (shift.isUrgent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // Certifications
            if (shift.requiredCertifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: shift.requiredCertifications.map((cert) => 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cert,
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action Button
            if (isAvailable && (_currentUser?.userType == UserType.steward || 
                                   _currentUser?.userType == UserType.siasteward))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: shift.isFullyStaffed ? null : () => _applyForShift(shift),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(shift.isFullyStaffed ? 'Fully Staffed' : 'Apply for Shift'),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Color _getStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.open:
        return const Color(0xFF1565C0);
      case ShiftStatus.active:
        return const Color(0xFFFF9800);
      case ShiftStatus.inProgress:
        return const Color(0xFF4CAF50);
      case ShiftStatus.completed:
        return const Color(0xFF2E7D32);
      case ShiftStatus.cancelled:
        return const Color(0xFFD32F2F);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Shifts'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.work),
                title: const Text('All Shifts'),
                onTap: () {
                  Navigator.pop(context);
                  _loadShifts();
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Urgent Shifts'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter for urgent shifts
                  setState(() {
                    _allShifts = _allShifts.where((shift) => shift.isUrgent).toList();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('High Pay (\$25+/hr)'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter for high pay shifts
                  setState(() {
                    _allShifts = _allShifts.where((shift) => shift.hourlyRate >= 25).toList();
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Today\'s Shifts'),
                onTap: () {
                  Navigator.pop(context);
                  // Filter for today's shifts
                  final today = DateTime.now();
                  setState(() {
                    _allShifts = _allShifts.where((shift) => 
                      shift.startTime.year == today.year &&
                      shift.startTime.month == today.month &&
                      shift.startTime.day == today.day
                    ).toList();
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}