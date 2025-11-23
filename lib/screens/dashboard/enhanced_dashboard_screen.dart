import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../models/shift.dart';
import '../../models/notification.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/shift_service.dart';
import '../../data/repositories/payroll_repository.dart';
import '../shifts/shifts_screen.dart';
import '../payroll/payroll_screen.dart';
import '../profile/profile_screen.dart';
import 'notifications_screen.dart';

class EnhancedDashboardScreen extends StatefulWidget {
  const EnhancedDashboardScreen({super.key});

  @override
  State<EnhancedDashboardScreen> createState() => _EnhancedDashboardScreenState();
}

class _EnhancedDashboardScreenState extends State<EnhancedDashboardScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final ShiftService _shiftService = ShiftService.instance;
  final PayrollRepository _payrollRepository = PayrollRepository.instance;

  User? _currentUser;
  List<AppNotification> _recentNotifications = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  // Dashboard stats
  int _todayShifts = 0;
  int _weeklyShifts = 0;
  double _monthlyEarnings = 0.0;
  int _pendingApplications = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = _authService.currentUser;
      
      if (_currentUser != null) {
        // Initialize notifications
        await _notificationService.initialize();
        
        // Load recent notifications (top 3)
        _recentNotifications = _notificationService.notifications.take(3).toList();
        
        // Load dashboard statistics
        await _loadStatistics();
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
      _animationController.forward();
    }
  }

  Future<void> _loadStatistics() async {
    if (_currentUser == null) return;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      // Load shifts statistics using the available getShifts method
      final shiftsResult = await _shiftService.getShifts(limit: 100);
      final allShifts = shiftsResult.success ? (shiftsResult.shifts ?? <Shift>[]) : <Shift>[];
      
      _todayShifts = allShifts.where((shift) {
        final shiftDate = DateTime(shift.startTime.year, shift.startTime.month, shift.startTime.day);
        return shiftDate.isAtSameMomentAs(today);
      }).length;

      _weeklyShifts = allShifts.where((shift) {
        return shift.startTime.isAfter(weekStart) && shift.startTime.isBefore(now);
      }).length;

      // Load payroll statistics
      final monthlyPayroll = await _payrollRepository.getMonthlyPayroll(
        _currentUser!.id,
        now.year,
        now.month,
      );
      
      _monthlyEarnings = monthlyPayroll?.totalEarnings ?? 0.0;

      // Count pending applications (for managers/admins)
      if (_currentUser!.userType == UserType.manager ||
          _currentUser!.userType == UserType.secondaryAdmin ||
          _currentUser!.userType == UserType.seniorAdmin) {
        final openShiftsResult = await _shiftService.getShifts(status: ShiftStatus.open);
        final openShifts = openShiftsResult.success ? (openShiftsResult.shifts ?? <Shift>[]) : <Shift>[];
        _pendingApplications = openShifts.where((shift) => 
          shift.assignedGuards < shift.requiredGuards
        ).length;
      }
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Dashboard...',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          const ShiftsScreen(),
          const PayrollScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                _buildQuickStats(),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildNotificationsCard(),
                const SizedBox(height: 20),
                _buildRecentActivity(),
                const SizedBox(height: 100), // Bottom padding for navigation
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Mankind Portal',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () => _navigateToNotifications(),
            ),
            if (_notificationService.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${_notificationService.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedIndex = 3; // Navigate to profile tab
            });
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: _currentUser?.profileImageUrl != null && _currentUser!.profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: _currentUser!.profileImageUrl!.startsWith('/')
                          ? Image.file(
                              File(_currentUser!.profileImageUrl!),
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                );
                              },
                            )
                          : Image.network(
                              _currentUser!.profileImageUrl!,
                              width: 34,
                              height: 34,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                );
                              },
                            ),
                    )
                  : Icon(
                      Icons.person,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _currentUser?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_currentUser?.firstName} ${_currentUser?.lastName}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _getUserTypeDisplayName(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getWelcomeMessage(),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Today\'s Shifts', '$_todayShifts', Icons.today, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('This Week', '$_weeklyShifts', Icons.calendar_view_week, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Monthly Earnings', '£${_monthlyEarnings.toStringAsFixed(0)}', Icons.payments, Colors.orange)),
            const SizedBox(width: 12),
            if (_currentUser?.userType == UserType.manager ||
                _currentUser?.userType == UserType.secondaryAdmin ||
                _currentUser?.userType == UserType.seniorAdmin)
              Expanded(child: _buildStatCard('Pending', '$_pendingApplications', Icons.pending_actions, Colors.red))
            else
              Expanded(child: _buildStatCard('Notifications', '${_notificationService.unreadCount}', Icons.notifications, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard('Browse Shifts', Icons.work, Colors.blue, () => setState(() => _selectedIndex = 1))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('View Payroll', Icons.payment, Colors.green, () => setState(() => _selectedIndex = 2))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard('My Profile', Icons.person, Colors.orange, () => setState(() => _selectedIndex = 3))),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard('Notifications', Icons.notifications, Colors.purple, _navigateToNotifications)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                if (_recentNotifications.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearAllNotifications,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: Text(
                      'Clear',
                      style: GoogleFonts.inter(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                TextButton(
                  onPressed: _navigateToNotifications,
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentNotifications.isEmpty)
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'New notifications will appear here',
                      style: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _recentNotifications.map((notification) => 
                _buildNotificationTile(notification)
              ).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: notification.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          notification.icon,
          color: notification.color,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: GoogleFonts.inter(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        notification.message,
        style: GoogleFonts.inter(fontSize: 12),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        notification.timeAgo,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
      onTap: () => _handleNotificationTap(notification),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Your activity will appear here as you use the app',
                    style: GoogleFonts.inter(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Activity item method removed - using empty state instead

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Shifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Payroll',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearAll();
      setState(() {
        _recentNotifications.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All notifications cleared',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to clear notifications',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  String _getUserTypeDisplayName() {
    switch (_currentUser?.userType) {
      case UserType.steward:
        return 'Security Steward';
      case UserType.siasteward:
        return 'SIA Licensed Steward';
      case UserType.manager:
        return 'Security Manager';
      case UserType.secondaryAdmin:
        return 'Secondary Administrator';
      case UserType.seniorAdmin:
        return 'Senior Administrator';
      default:
        return 'Team Member';
    }
  }

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return '$greeting! Here\'s your dashboard overview for today. Stay safe and have a productive shift.';
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    _notificationService.markAsRead(notification.id);
    
    // Navigate based on action URL
    if (notification.actionUrl != null) {
      switch (notification.actionUrl) {
        case '/shifts':
          setState(() => _selectedIndex = 1);
          break;
        case '/payroll':
          setState(() => _selectedIndex = 2);
          break;
        case '/profile':
          setState(() => _selectedIndex = 3);
          break;
        default:
          _navigateToNotifications();
      }
    }
  }
}
