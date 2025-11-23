import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/shift.dart';
import '../models/booking.dart';

class LocalStorageService {
  static const String _userKey = 'current_user';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _shiftsKey = 'cached_shifts';
  static const String _myShiftsKey = 'cached_my_shifts';
  static const String _bookingsKey = 'cached_bookings';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _appSettingsKey = 'app_settings';
  static const String _offlineActionsKey = 'offline_actions';
  static const String _lastSyncKey = 'last_sync_timestamp';

  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance ??= LocalStorageService._();
  LocalStorageService._();

  SharedPreferences? _prefs;

  /// Initialize the local storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure preferences are initialized
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== Authentication Storage ====================

  /// Save authentication token
  Future<bool> saveAuthToken(String token) async {
    final prefs = await _preferences;
    return prefs.setString(_authTokenKey, token);
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    final prefs = await _preferences;
    return prefs.getString(_authTokenKey);
  }

  /// Save refresh token
  Future<bool> saveRefreshToken(String token) async {
    final prefs = await _preferences;
    return prefs.setString(_refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(_refreshTokenKey);
  }

  /// Save current user
  Future<bool> saveCurrentUser(User user) async {
    final prefs = await _preferences;
    return prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Get current user
  Future<User?> getCurrentUser() async {
    final prefs = await _preferences;
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Error parsing cached user: $e');
        return null;
      }
    }
    return null;
  }

  /// Clear authentication data
  Future<bool> clearAuthData() async {
    final prefs = await _preferences;
    final results = await Future.wait([
      prefs.remove(_authTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userKey),
    ]);
    return results.every((result) => result);
  }

  // ==================== Shifts Storage ====================

  /// Cache shifts data
  Future<bool> cacheShifts(List<Shift> shifts) async {
    final prefs = await _preferences;
    final shiftsJson = shifts.map((shift) => shift.toJson()).toList();
    return prefs.setString(_shiftsKey, jsonEncode(shiftsJson));
  }

  /// Get cached shifts
  Future<List<Shift>> getCachedShifts() async {
    final prefs = await _preferences;
    final shiftsJson = prefs.getString(_shiftsKey);
    if (shiftsJson != null) {
      try {
        final List<dynamic> shiftsList = jsonDecode(shiftsJson);
        return shiftsList.map((json) => Shift.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing cached shifts: $e');
        return [];
      }
    }
    return [];
  }

  /// Cache my shifts data
  Future<bool> cacheMyShifts(List<Shift> shifts) async {
    final prefs = await _preferences;
    final shiftsJson = shifts.map((shift) => shift.toJson()).toList();
    return prefs.setString(_myShiftsKey, jsonEncode(shiftsJson));
  }

  /// Get cached my shifts
  Future<List<Shift>> getCachedMyShifts() async {
    final prefs = await _preferences;
    final shiftsJson = prefs.getString(_myShiftsKey);
    if (shiftsJson != null) {
      try {
        final List<dynamic> shiftsList = jsonDecode(shiftsJson);
        return shiftsList.map((json) => Shift.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing cached my shifts: $e');
        return [];
      }
    }
    return [];
  }

  // ==================== Bookings Storage ====================

  /// Cache bookings data
  Future<bool> cacheBookings(List<Booking> bookings) async {
    final prefs = await _preferences;
    final bookingsJson = bookings.map((booking) => booking.toJson()).toList();
    return prefs.setString(_bookingsKey, jsonEncode(bookingsJson));
  }

  /// Get cached bookings
  Future<List<Booking>> getCachedBookings() async {
    final prefs = await _preferences;
    final bookingsJson = prefs.getString(_bookingsKey);
    if (bookingsJson != null) {
      try {
        final List<dynamic> bookingsList = jsonDecode(bookingsJson);
        return bookingsList.map((json) => Booking.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing cached bookings: $e');
        return [];
      }
    }
    return [];
  }

  // ==================== User Preferences ====================

  /// Save user preferences
  Future<bool> saveUserPreferences(UserPreferences preferences) async {
    final prefs = await _preferences;
    return prefs.setString(_userPreferencesKey, jsonEncode(preferences.toJson()));
  }

  /// Get user preferences
  Future<UserPreferences> getUserPreferences() async {
    final prefs = await _preferences;
    final preferencesJson = prefs.getString(_userPreferencesKey);
    if (preferencesJson != null) {
      try {
        return UserPreferences.fromJson(jsonDecode(preferencesJson));
      } catch (e) {
        print('Error parsing user preferences: $e');
        return UserPreferences.defaultPreferences();
      }
    }
    return UserPreferences.defaultPreferences();
  }

  // ==================== App Settings ====================

  /// Save app settings
  Future<bool> saveAppSettings(AppSettings settings) async {
    final prefs = await _preferences;
    return prefs.setString(_appSettingsKey, jsonEncode(settings.toJson()));
  }

  /// Get app settings
  Future<AppSettings> getAppSettings() async {
    final prefs = await _preferences;
    final settingsJson = prefs.getString(_appSettingsKey);
    if (settingsJson != null) {
      try {
        return AppSettings.fromJson(jsonDecode(settingsJson));
      } catch (e) {
        print('Error parsing app settings: $e');
        return AppSettings.defaultSettings();
      }
    }
    return AppSettings.defaultSettings();
  }

  // ==================== Offline Actions ====================

  /// Save offline action for later sync
  Future<bool> saveOfflineAction(OfflineAction action) async {
    final prefs = await _preferences;
    final actionsJson = prefs.getString(_offlineActionsKey);
    List<OfflineAction> actions = [];
    
    if (actionsJson != null) {
      try {
        final List<dynamic> actionsList = jsonDecode(actionsJson);
        actions = actionsList.map((json) => OfflineAction.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing offline actions: $e');
      }
    }
    
    actions.add(action);
    final updatedActionsJson = actions.map((action) => action.toJson()).toList();
    return prefs.setString(_offlineActionsKey, jsonEncode(updatedActionsJson));
  }

  /// Get all offline actions
  Future<List<OfflineAction>> getOfflineActions() async {
    final prefs = await _preferences;
    final actionsJson = prefs.getString(_offlineActionsKey);
    if (actionsJson != null) {
      try {
        final List<dynamic> actionsList = jsonDecode(actionsJson);
        return actionsList.map((json) => OfflineAction.fromJson(json)).toList();
      } catch (e) {
        print('Error parsing offline actions: $e');
        return [];
      }
    }
    return [];
  }

  /// Remove offline action after successful sync
  Future<bool> removeOfflineAction(String actionId) async {
    final prefs = await _preferences;
    final actionsJson = prefs.getString(_offlineActionsKey);
    if (actionsJson != null) {
      try {
        final List<dynamic> actionsList = jsonDecode(actionsJson);
        final actions = actionsList.map((json) => OfflineAction.fromJson(json)).toList();
        actions.removeWhere((action) => action.id == actionId);
        
        final updatedActionsJson = actions.map((action) => action.toJson()).toList();
        return prefs.setString(_offlineActionsKey, jsonEncode(updatedActionsJson));
      } catch (e) {
        print('Error removing offline action: $e');
        return false;
      }
    }
    return true;
  }

  /// Clear all offline actions
  Future<bool> clearOfflineActions() async {
    final prefs = await _preferences;
    return prefs.remove(_offlineActionsKey);
  }

  // ==================== Sync Management ====================

  /// Save last sync timestamp
  Future<bool> saveLastSyncTimestamp(DateTime timestamp) async {
    final prefs = await _preferences;
    return prefs.setString(_lastSyncKey, timestamp.toIso8601String());
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await _preferences;
    final timestampString = prefs.getString(_lastSyncKey);
    if (timestampString != null) {
      try {
        return DateTime.parse(timestampString);
      } catch (e) {
        print('Error parsing last sync timestamp: $e');
        return null;
      }
    }
    return null;
  }

  // ==================== Generic Storage Methods ====================

  /// Save string value
  Future<bool> saveString(String key, String value) async {
    final prefs = await _preferences;
    return prefs.setString(key, value);
  }

  /// Get string value
  Future<String?> getString(String key) async {
    final prefs = await _preferences;
    return prefs.getString(key);
  }

  /// Save boolean value
  Future<bool> saveBool(String key, bool value) async {
    final prefs = await _preferences;
    return prefs.setBool(key, value);
  }

  /// Get boolean value
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _preferences;
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Save integer value
  Future<bool> saveInt(String key, int value) async {
    final prefs = await _preferences;
    return prefs.setInt(key, value);
  }

  /// Get integer value
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await _preferences;
    return prefs.getInt(key) ?? defaultValue;
  }

  /// Save double value
  Future<bool> saveDouble(String key, double value) async {
    final prefs = await _preferences;
    return prefs.setDouble(key, value);
  }

  /// Get double value
  Future<double> getDouble(String key, {double defaultValue = 0.0}) async {
    final prefs = await _preferences;
    return prefs.getDouble(key) ?? defaultValue;
  }

  /// Remove value by key
  Future<bool> remove(String key) async {
    final prefs = await _preferences;
    return prefs.remove(key);
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    final prefs = await _preferences;
    return prefs.containsKey(key);
  }

  /// Clear all stored data
  Future<bool> clearAll() async {
    final prefs = await _preferences;
    return prefs.clear();
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    final prefs = await _preferences;
    return prefs.getKeys();
  }
}

// ==================== Data Models for Storage ====================

class UserPreferences {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final String language;
  final String theme;
  final bool biometricAuth;
  final double locationRadius;
  final List<String> preferredShiftTypes;

  UserPreferences({
    required this.notificationsEnabled,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.language,
    required this.theme,
    required this.biometricAuth,
    required this.locationRadius,
    required this.preferredShiftTypes,
  });

  factory UserPreferences.defaultPreferences() {
    return UserPreferences(
      notificationsEnabled: true,
      emailNotifications: true,
      pushNotifications: true,
      language: 'en',
      theme: 'system',
      biometricAuth: false,
      locationRadius: 50.0,
      preferredShiftTypes: [],
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      language: json['language'] ?? 'en',
      theme: json['theme'] ?? 'system',
      biometricAuth: json['biometricAuth'] ?? false,
      locationRadius: (json['locationRadius'] ?? 50.0).toDouble(),
      preferredShiftTypes: List<String>.from(json['preferredShiftTypes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'language': language,
      'theme': theme,
      'biometricAuth': biometricAuth,
      'locationRadius': locationRadius,
      'preferredShiftTypes': preferredShiftTypes,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    String? language,
    String? theme,
    bool? biometricAuth,
    double? locationRadius,
    List<String>? preferredShiftTypes,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      locationRadius: locationRadius ?? this.locationRadius,
      preferredShiftTypes: preferredShiftTypes ?? this.preferredShiftTypes,
    );
  }
}

class AppSettings {
  final String apiBaseUrl;
  final int cacheExpirationHours;
  final bool offlineModeEnabled;
  final int maxOfflineActions;
  final bool debugMode;

  AppSettings({
    required this.apiBaseUrl,
    required this.cacheExpirationHours,
    required this.offlineModeEnabled,
    required this.maxOfflineActions,
    required this.debugMode,
  });

  factory AppSettings.defaultSettings() {
    return AppSettings(
      apiBaseUrl: 'https://api.securityshift.com',
      cacheExpirationHours: 24,
      offlineModeEnabled: true,
      maxOfflineActions: 100,
      debugMode: false,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      apiBaseUrl: json['apiBaseUrl'] ?? 'https://api.securityshift.com',
      cacheExpirationHours: json['cacheExpirationHours'] ?? 24,
      offlineModeEnabled: json['offlineModeEnabled'] ?? true,
      maxOfflineActions: json['maxOfflineActions'] ?? 100,
      debugMode: json['debugMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiBaseUrl': apiBaseUrl,
      'cacheExpirationHours': cacheExpirationHours,
      'offlineModeEnabled': offlineModeEnabled,
      'maxOfflineActions': maxOfflineActions,
      'debugMode': debugMode,
    };
  }
}

class OfflineAction {
  final String id;
  final String type;
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final int retryCount;

  OfflineAction({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory OfflineAction.fromJson(Map<String, dynamic> json) {
    return OfflineAction(
      id: json['id'],
      type: json['type'],
      endpoint: json['endpoint'],
      method: json['method'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  OfflineAction copyWith({
    int? retryCount,
  }) {
    return OfflineAction(
      id: id,
      type: type,
      endpoint: endpoint,
      method: method,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}