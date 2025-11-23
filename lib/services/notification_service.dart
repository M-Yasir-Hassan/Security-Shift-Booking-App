import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final AuthService _authService = AuthService.instance;
  static const String _notificationsKey = 'user_notifications';

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Initialize notifications for current user
  Future<void> initialize() async {
    await _loadNotifications();
    // No sample notifications - only real data will be shown
  }

  /// Load notifications from local storage
  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final notificationsJson = prefs.getString('${_notificationsKey}_${currentUser.id}');
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications = notificationsList
            .map((json) => AppNotification.fromJson(json))
            .toList();
        
        // Sort by creation date (newest first)
        _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  /// Save notifications to local storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final notificationsJson = jsonEncode(
        _notifications.map((n) => n.toJson()).toList(),
      );
      await prefs.setString('${_notificationsKey}_${currentUser.id}', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await _saveNotifications();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
  }

  // Sample notification generation removed - only real data will be shown

  /// Create notification for shift assignment
  Future<void> notifyShiftAssignment(String shiftTitle, String location) async {
    await addNotification(AppNotification(
      id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Shift Assigned',
      message: 'You have been assigned to $shiftTitle at $location',
      type: NotificationType.shiftAssignment,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      actionUrl: '/shifts',
    ));
  }

  /// Create notification for payroll update
  Future<void> notifyPayrollUpdate(double amount) async {
    await addNotification(AppNotification(
      id: 'payroll_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payroll Updated',
      message: 'Your payroll has been updated. New total: £${amount.toStringAsFixed(2)}',
      type: NotificationType.payrollUpdate,
      priority: NotificationPriority.medium,
      createdAt: DateTime.now(),
      actionUrl: '/payroll',
    ));
  }

  /// Create notification for shift reminder
  Future<void> notifyShiftReminder(String shiftTitle, DateTime shiftTime) async {
    final hoursUntil = shiftTime.difference(DateTime.now()).inHours;
    await addNotification(AppNotification(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Shift Reminder',
      message: '$shiftTitle starts in $hoursUntil hours',
      type: NotificationType.shiftReminder,
      priority: NotificationPriority.high,
      createdAt: DateTime.now(),
      actionUrl: '/shifts',
    ));
  }
}
