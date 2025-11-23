import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordService {
  static final PasswordService _instance = PasswordService._internal();
  static PasswordService get instance => _instance;
  PasswordService._internal();

  /// Generate a random salt
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  /// Hash a password with salt
  String hashPassword(String password) {
    final salt = _generateSalt();
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Verify a password against a hash
  bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final hash = parts[1];
      
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      
      return digest.toString() == hash;
    } catch (e) {
      return false;
    }
  }

  /// Validate password strength
  bool isPasswordValid(String password) {
    if (password.length < 6) return false;
    
    // Check for at least one letter and one number
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    return hasLetter && hasNumber;
  }

  /// Get password strength message
  String getPasswordStrengthMessage(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    
    if (!hasLetter) {
      return 'Password must contain at least one letter';
    }
    
    if (!hasNumber) {
      return 'Password must contain at least one number';
    }
    
    return 'Password is valid';
  }

  /// Generate a secure random password
  String generateSecurePassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
}
