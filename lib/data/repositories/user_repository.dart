import 'dart:convert';
import '../../core/repositories/base_repository.dart';
import '../../core/constants/database_constants.dart';
import '../../models/user.dart';
import '../../services/password_service.dart';

class UserRepository extends BaseRepository {
  static final UserRepository _instance = UserRepository._internal();
  static UserRepository get instance => _instance;
  UserRepository._internal();

  final PasswordService _passwordService = PasswordService.instance;

  // Create user with password
  Future<String?> createUserWithPassword(User user, String password) async {
    try {
      final hashedPassword = _passwordService.hashPassword(password);
      
      final userData = {
        DatabaseConstants.userId: user.id,
        DatabaseConstants.userFirstName: user.firstName,
        DatabaseConstants.userLastName: user.lastName,
        DatabaseConstants.userEmail: user.email,
        DatabaseConstants.userPhoneNumber: user.phoneNumber,
        DatabaseConstants.userPasswordHash: hashedPassword,
        DatabaseConstants.userType: user.userType.name,
        DatabaseConstants.userProfileImageUrl: user.profileImageUrl,
        DatabaseConstants.userIsActive: user.isActive ? 1 : 0,
        DatabaseConstants.userIsApproved: user.isApproved ? 1 : 0,
        DatabaseConstants.userCreatedAt: user.createdAt.toIso8601String(),
        DatabaseConstants.userUpdatedAt: user.updatedAt.toIso8601String(),
      };

      await insert(DatabaseConstants.usersTable, userData);

      // Insert user profile if exists
      if (user.profile != null) {
        final profileData = {
          DatabaseConstants.profileUserId: user.id,
          DatabaseConstants.profileLicenseNumber: user.profile!.licenseNumber,
          DatabaseConstants.profileLicenseExpiry: user.profile!.licenseExpiry?.toIso8601String(),
          DatabaseConstants.profileCertifications: jsonEncode(user.profile!.certifications),
          DatabaseConstants.profileHourlyRate: user.profile!.hourlyRate,
          DatabaseConstants.profileEmergencyContactName: user.profile!.emergencyContactName,
          DatabaseConstants.profileEmergencyContactPhone: user.profile!.emergencyContactPhone,
          DatabaseConstants.profileAddress: user.profile!.address,
        };

        await insert(DatabaseConstants.userProfilesTable, profileData);
      }

      return user.id;
    } catch (e) {
      print('Error creating user with password: $e');
      return null;
    }
  }

  // Authenticate user with email and password
  Future<User?> authenticateUser(String email, String password) async {
    try {
      final userResults = await query(
        DatabaseConstants.usersTable,
        where: '${DatabaseConstants.userEmail} = ?',
        whereArgs: [email],
      );

      if (userResults.isEmpty) return null;

      final userData = userResults.first;
      final storedPasswordHash = userData[DatabaseConstants.userPasswordHash] as String;

      // Verify password
      if (!_passwordService.verifyPassword(password, storedPasswordHash)) {
        return null;
      }

      // Check if user is active
      if ((userData[DatabaseConstants.userIsActive] as int) != 1) {
        return null;
      }

      final userId = userData[DatabaseConstants.userId] as String;
      return await getUserById(userId);
    } catch (e) {
      print('Error authenticating user: $e');
      return null;
    }
  }

  // Create user (legacy method for backward compatibility)
  Future<String?> createUser(User user) async {
    try {
      final userData = {
        DatabaseConstants.userId: user.id,
        DatabaseConstants.userFirstName: user.firstName,
        DatabaseConstants.userLastName: user.lastName,
        DatabaseConstants.userEmail: user.email,
        DatabaseConstants.userPhoneNumber: user.phoneNumber,
        DatabaseConstants.userType: user.userType.name,
        DatabaseConstants.userProfileImageUrl: user.profileImageUrl,
        DatabaseConstants.userIsActive: user.isActive ? 1 : 0,
        DatabaseConstants.userIsApproved: user.isApproved ? 1 : 0,
        DatabaseConstants.userCreatedAt: user.createdAt.toIso8601String(),
        DatabaseConstants.userUpdatedAt: user.updatedAt.toIso8601String(),
      };

      await insert(DatabaseConstants.usersTable, userData);

      // Insert user profile if exists
      if (user.profile != null) {
        final profileData = {
          DatabaseConstants.profileUserId: user.id,
          DatabaseConstants.profileLicenseNumber: user.profile!.licenseNumber,
          DatabaseConstants.profileLicenseExpiry: user.profile!.licenseExpiry?.toIso8601String(),
          DatabaseConstants.profileCertifications: jsonEncode(user.profile!.certifications),
          DatabaseConstants.profileHourlyRate: user.profile!.hourlyRate,
          DatabaseConstants.profileEmergencyContactName: user.profile!.emergencyContactName,
          DatabaseConstants.profileEmergencyContactPhone: user.profile!.emergencyContactPhone,
          DatabaseConstants.profileAddress: user.profile!.address,
        };

        await insert(DatabaseConstants.userProfilesTable, profileData);
      }

      return user.id;
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final userResults = await query(
        DatabaseConstants.usersTable,
        where: '${DatabaseConstants.userId} = ?',
        whereArgs: [userId],
      );

      if (userResults.isEmpty) return null;

      final userData = userResults.first;

      // Get user profile
      final profileResults = await query(
        DatabaseConstants.userProfilesTable,
        where: '${DatabaseConstants.profileUserId} = ?',
        whereArgs: [userId],
      );

      UserProfile? profile;
      if (profileResults.isNotEmpty) {
        final profileData = profileResults.first;
        profile = UserProfile(
          userId: userId,
          licenseNumber: profileData[DatabaseConstants.profileLicenseNumber] as String?,
          licenseExpiry: profileData[DatabaseConstants.profileLicenseExpiry] != null
              ? DateTime.parse(profileData[DatabaseConstants.profileLicenseExpiry] as String)
              : null,
          certifications: profileData[DatabaseConstants.profileCertifications] != null
              ? List<String>.from(jsonDecode(profileData[DatabaseConstants.profileCertifications] as String))
              : [],
          hourlyRate: profileData[DatabaseConstants.profileHourlyRate] as double?,
          emergencyContactName: profileData[DatabaseConstants.profileEmergencyContactName] as String?,
          emergencyContactPhone: profileData[DatabaseConstants.profileEmergencyContactPhone] as String?,
          address: profileData[DatabaseConstants.profileAddress] as String?,
        );
      }

      return User(
        id: userData[DatabaseConstants.userId] as String,
        firstName: userData[DatabaseConstants.userFirstName] as String,
        lastName: userData[DatabaseConstants.userLastName] as String,
        email: userData[DatabaseConstants.userEmail] as String,
        phoneNumber: userData[DatabaseConstants.userPhoneNumber] as String,
        userType: UserType.values.firstWhere(
          (type) => type.name == userData[DatabaseConstants.userType],
          orElse: () => UserType.steward,
        ),
        profileImageUrl: userData[DatabaseConstants.userProfileImageUrl] as String?,
        createdAt: DateTime.parse(userData[DatabaseConstants.userCreatedAt] as String),
        updatedAt: DateTime.parse(userData[DatabaseConstants.userUpdatedAt] as String),
        isActive: (userData[DatabaseConstants.userIsActive] as int) == 1,
        isApproved: (userData[DatabaseConstants.userIsApproved] as int?) == 1,
        profile: profile,
      );
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final results = await query(
        DatabaseConstants.usersTable,
        where: '${DatabaseConstants.userEmail} = ?',
        whereArgs: [email],
      );

      if (results.isEmpty) return null;

      final userId = results.first[DatabaseConstants.userId] as String;
      return await getUserById(userId);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Update user
  Future<bool> updateUser(User user) async {
    try {
      final userData = {
        DatabaseConstants.userFirstName: user.firstName,
        DatabaseConstants.userLastName: user.lastName,
        DatabaseConstants.userEmail: user.email,
        DatabaseConstants.userPhoneNumber: user.phoneNumber,
        DatabaseConstants.userType: user.userType.name,
        DatabaseConstants.userProfileImageUrl: user.profileImageUrl,
        DatabaseConstants.userIsActive: user.isActive ? 1 : 0,
        DatabaseConstants.userIsApproved: user.isApproved ? 1 : 0,
        DatabaseConstants.userUpdatedAt: DateTime.now().toIso8601String(),
      };

      final result = await update(
        DatabaseConstants.usersTable,
        userData,
        where: '${DatabaseConstants.userId} = ?',
        whereArgs: [user.id],
      );

      // Update profile if exists
      if (user.profile != null) {
        final profileData = {
          DatabaseConstants.profileLicenseNumber: user.profile!.licenseNumber,
          DatabaseConstants.profileLicenseExpiry: user.profile!.licenseExpiry?.toIso8601String(),
          DatabaseConstants.profileCertifications: jsonEncode(user.profile!.certifications),
          DatabaseConstants.profileHourlyRate: user.profile!.hourlyRate,
          DatabaseConstants.profileEmergencyContactName: user.profile!.emergencyContactName,
          DatabaseConstants.profileEmergencyContactPhone: user.profile!.emergencyContactPhone,
          DatabaseConstants.profileAddress: user.profile!.address,
        };

        await update(
          DatabaseConstants.userProfilesTable,
          profileData,
          where: '${DatabaseConstants.profileUserId} = ?',
          whereArgs: [user.id],
        );
      }

      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      return await transaction((txn) async {
        // Delete user profile first
        await txn.delete(
          DatabaseConstants.userProfilesTable,
          where: '${DatabaseConstants.profileUserId} = ?',
          whereArgs: [userId],
        );

        // Delete user
        final result = await txn.delete(
          DatabaseConstants.usersTable,
          where: '${DatabaseConstants.userId} = ?',
          whereArgs: [userId],
        );

        return result > 0;
      });
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Get all users with pagination
  Future<List<User>> getAllUsers({
    int limit = 20,
    int offset = 0,
    UserType? userType,
    bool? isActive,
  }) async {
    try {
      String? whereClause;
      List<Object?> whereArgs = [];

      if (userType != null || isActive != null) {
        List<String> conditions = [];
        
        if (userType != null) {
          conditions.add('${DatabaseConstants.userType} = ?');
          whereArgs.add(userType.name);
        }
        
        if (isActive != null) {
          conditions.add('${DatabaseConstants.userIsActive} = ?');
          whereArgs.add(isActive ? 1 : 0);
        }
        
        whereClause = conditions.join(' AND ');
      }

      final results = await query(
        DatabaseConstants.usersTable,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '${DatabaseConstants.userCreatedAt} DESC',
        limit: limit,
        offset: offset,
      );

      final users = <User>[];
      for (final userData in results) {
        final userId = userData[DatabaseConstants.userId] as String;
        final user = await getUserById(userId);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Check if email exists
  Future<bool> emailExists(String email) async {
    try {
      final results = await query(
        DatabaseConstants.usersTable,
        columns: [DatabaseConstants.userId],
        where: '${DatabaseConstants.userEmail} = ?',
        whereArgs: [email],
      );

      return results.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Search users
  Future<List<User>> searchUsers(String searchTerm, {int limit = 20}) async {
    try {
      final results = await query(
        DatabaseConstants.usersTable,
        where: '''
          ${DatabaseConstants.userFirstName} LIKE ? OR 
          ${DatabaseConstants.userLastName} LIKE ? OR 
          ${DatabaseConstants.userEmail} LIKE ?
        ''',
        whereArgs: ['%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: '${DatabaseConstants.userFirstName}, ${DatabaseConstants.userLastName}',
        limit: limit,
      );

      final users = <User>[];
      for (final userData in results) {
        final userId = userData[DatabaseConstants.userId] as String;
        final user = await getUserById(userId);
        if (user != null) {
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
