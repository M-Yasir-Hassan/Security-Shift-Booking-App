import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../data/repositories/user_repository.dart';
import '../core/database/database_helper.dart';
import 'password_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final UserRepository _userRepository = UserRepository.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final PasswordService _passwordService = PasswordService.instance;

  User? _currentUser;
  String? _authToken;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  /// Initialize the auth service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize database
      await _databaseHelper.database;

      // Load saved user and token
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      
      print('Auth initialization - Token exists: ${_authToken != null}, User data exists: ${userJson != null}');
      
      // Only load user if we have both token and user data
      if (_authToken != null && _authToken!.isNotEmpty && 
          userJson != null && userJson.isNotEmpty) {
        try {
          final userData = jsonDecode(userJson);
          _currentUser = User.fromJson(userData);
          print('User loaded successfully: ${_currentUser?.email}');
        } catch (e) {
          print('Error parsing user data: $e - clearing auth data');
          _currentUser = null;
          _authToken = null;
          await prefs.remove(_tokenKey);
          await prefs.remove(_userKey);
        }
      } else {
        // Incomplete data - clear auth data only
        print('Incomplete auth data - clearing auth preferences');
        _currentUser = null;
        _authToken = null;
        if (_authToken != null) await prefs.remove(_tokenKey);
        if (userJson != null) await prefs.remove(_userKey);
      }

      _isInitialized = true;
      print('Auth service initialized - isAuthenticated: $isAuthenticated');
    } catch (e) {
      print('Error initializing auth service: $e');
      // Ensure clean state on error
      _currentUser = null;
      _authToken = null;
      _isInitialized = true;
    }
  }

  /// Register a new user
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required UserType userType,
    String? profileImageUrl,
  }) async {
    try {
      // Validate password strength
      if (!_passwordService.isPasswordValid(password)) {
        return AuthResult.failure(_passwordService.getPasswordStrengthMessage(password));
      }

      // Check if email already exists
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult.failure('Email already exists');
      }

      // Create new user
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        userType: userType,
        profileImageUrl: profileImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      // Save user to database with password
      final userId = await _userRepository.createUserWithPassword(user, password);
      if (userId != null) {
        // Generate auth token
        _authToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
        _currentUser = user;

        // Save to local storage
        await _saveAuthData();

        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Failed to create user');
      }
    } catch (e) {
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate user with password
      final user = await _userRepository.authenticateUser(email, password);
      if (user == null) {
        return AuthResult.failure('Invalid email or password');
      }

      if (!user.isActive) {
        return AuthResult.failure('Account is deactivated');
      }

      // Admin users don't need approval, only regular users (SIA/Steward)
      if (!user.isApproved && (user.userType == UserType.steward || user.userType == UserType.siasteward)) {
        return AuthResult.failure('Account is pending approval by admin');
      }

      // Generate auth token
      _authToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = user;

      // Save to local storage
      await _saveAuthData();

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      // Clear in-memory data first
      _currentUser = null;
      _authToken = null;

      // Clear local storage data
      final prefs = await SharedPreferences.getInstance();
      
      // Remove specific auth keys
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      
      // Also remove any other auth-related keys that might exist
      final allKeys = prefs.getKeys();
      final authKeys = allKeys.where((key) => 
        key.contains('auth') || 
        key.contains('user') || 
        key.contains('token') ||
        key.contains('login') ||
        key.contains('session')
      ).toList();
      
      for (final key in authKeys) {
        await prefs.remove(key);
      }
      
      // Force commit changes
      await prefs.commit();
      
      print('LOGOUT FIXED: User logged out successfully - removed ${authKeys.length + 2} auth keys');
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, ensure in-memory data is cleared
      _currentUser = null;
      _authToken = null;
    }
  }

  /// Update current user
  Future<AuthResult> updateUser(User user) async {
    try {
      final success = await _userRepository.updateUser(user);
      if (success) {
        _currentUser = user;
        await _saveAuthData();
        return AuthResult.success(user);
      } else {
        return AuthResult.failure('Failed to update user');
      }
    } catch (e) {
      return AuthResult.failure('Update failed: ${e.toString()}');
    }
  }

  /// Get current user from database (refresh)
  Future<User?> getCurrentUser() async {
    if (_currentUser == null) return null;

    try {
      final user = await _userRepository.getUserById(_currentUser!.id);
      if (user != null) {
        _currentUser = user;
        await _saveAuthData();
      }
      return user;
    } catch (e) {
      print('Error getting current user: $e');
      return _currentUser;
    }
  }

  /// Check if user has permission
  bool hasPermission(Permission permission) {
    if (_currentUser == null) return false;

    switch (permission) {
      case Permission.createShifts:
        return _currentUser!.userType == UserType.manager ||
               _currentUser!.userType == UserType.secondaryAdmin ||
               _currentUser!.userType == UserType.seniorAdmin;
      
      case Permission.manageUsers:
        return _currentUser!.userType == UserType.secondaryAdmin ||
               _currentUser!.userType == UserType.seniorAdmin;
      
      case Permission.viewAllShifts:
        return _currentUser!.userType == UserType.manager ||
               _currentUser!.userType == UserType.secondaryAdmin ||
               _currentUser!.userType == UserType.seniorAdmin;
      
      case Permission.applyForShifts:
        return _currentUser!.userType == UserType.steward ||
               _currentUser!.userType == UserType.siasteward;
      
      case Permission.viewPayroll:
        return true; // All users can view their own payroll
      
      case Permission.managePayroll:
        return _currentUser!.userType == UserType.secondaryAdmin ||
               _currentUser!.userType == UserType.seniorAdmin;
    }
  }

  /// Get auth headers for API requests
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_authToken != null) {
        await prefs.setString(_tokenKey, _authToken!);
      }
      
      if (_currentUser != null) {
        await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      }
    } catch (e) {
      print('Error saving auth data: $e');
    }
  }

  /// Create sample admin user for testing
  Future<void> createSampleUsers() async {
    try {
      // Check if admin already exists
      final existingAdmin = await _userRepository.getUserByEmail('admin@mankindportal.com');
      if (existingAdmin != null) return;

      // Create senior admin with password "admin123"
      final seniorAdmin = User(
        id: 'admin_001',
        firstName: 'Senior',
        lastName: 'Admin',
        email: 'admin@mankindportal.com',
        phoneNumber: '+44 20 1234 5678',
        userType: UserType.seniorAdmin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isApproved: true,
      );

      await _userRepository.createUserWithPassword(seniorAdmin, 'admin123');

      // Create secondary admin with password "admin123"
      final secondaryAdmin = User(
        id: 'admin_002',
        firstName: 'Secondary',
        lastName: 'Admin',
        email: 'secondary@mankindportal.com',
        phoneNumber: '+44 20 1234 5679',
        userType: UserType.secondaryAdmin,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isApproved: true,
      );

      await _userRepository.createUserWithPassword(secondaryAdmin, 'admin123');

      // Create manager with password "manager123"
      final manager = User(
        id: 'manager_001',
        firstName: 'Security',
        lastName: 'Manager',
        email: 'manager@mankindportal.com',
        phoneNumber: '+44 20 1234 5680',
        userType: UserType.manager,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isApproved: true,
      );

      await _userRepository.createUserWithPassword(manager, 'manager123');

      // Create sample steward with password "steward123"
      final steward = User(
        id: 'steward_001',
        firstName: 'John',
        lastName: 'Steward',
        email: 'steward@mankindportal.com',
        phoneNumber: '+44 20 1234 5681',
        userType: UserType.steward,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isApproved: false,
      );

      await _userRepository.createUserWithPassword(steward, 'steward123');

      // Create sample SIA steward with password "sia123"
      final siasteward = User(
        id: 'siasteward_001',
        firstName: 'Jane',
        lastName: 'SIA Steward',
        email: 'sia@mankindportal.com',
        phoneNumber: '+44 20 1234 5682',
        userType: UserType.siasteward,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        isApproved: false,
      );

      await _userRepository.createUserWithPassword(siasteward, 'sia123');

      print('Sample users created successfully');
    } catch (e) {
      print('Error creating sample users: $e');
    }
  }
}

/// Auth result class
class AuthResult {
  final bool success;
  final User? user;
  final String? message;

  AuthResult._({
    required this.success,
    this.user,
    this.message,
  });

  factory AuthResult.success(User user) {
    return AuthResult._(success: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message);
  }
}

/// Permission enum
enum Permission {
  createShifts,
  manageUsers,
  viewAllShifts,
  applyForShifts,
  viewPayroll,
  managePayroll,
}
