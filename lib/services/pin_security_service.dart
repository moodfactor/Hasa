import 'dart:developer';
import 'package:flutter/services.dart';

class PinSecurityService {
  static const _pinChannel = MethodChannel('com.hasa.app/pin');

  static final PinSecurityService _instance = PinSecurityService._internal();

  factory PinSecurityService() {
    return _instance;
  }

  PinSecurityService._internal();

  /// Save PIN securely using EncryptedSharedPreferences
  Future<bool> savePin(String pin) async {
    try {
      final bool result =
          await _pinChannel.invokeMethod('savePin', {'pin': pin});
      return result;
    } on PlatformException catch (e) {
      log('Failed to save PIN: ${e.message}');
      return false;
    }
  }

  /// Verify if the entered PIN matches the stored PIN
  Future<bool> verifyPin(String pin) async {
    try {
      final bool result =
          await _pinChannel.invokeMethod('verifyPin', {'pin': pin});
      return result;
    } on PlatformException catch (e) {
      log('Failed to verify PIN: ${e.message}');
      return false;
    }
  }

  /// Check if a PIN has been set
  Future<bool> isPinSet() async {
    try {
      final bool result = await _pinChannel.invokeMethod('isPinSet');
      return result;
    } on PlatformException catch (e) {
      log('Failed to check if PIN is set: ${e.message}');
      return false;
    }
  }

  /// Reset the stored PIN
  Future<bool> resetPin() async {
    try {
      final bool result = await _pinChannel.invokeMethod('resetPin');
      return result;
    } on PlatformException catch (e) {
      log('Failed to reset PIN: ${e.message}');
      return false;
    }
  }

  /// Increment the failed attempts counter
  Future<int> incrementAttempts() async {
    try {
      final int attempts = await _pinChannel.invokeMethod('incrementAttempts');
      return attempts;
    } on PlatformException catch (e) {
      log('Failed to increment attempts: ${e.message}');
      return 0;
    }
  }

  /// Reset the failed attempts counter
  Future<bool> resetAttempts() async {
    try {
      final bool result = await _pinChannel.invokeMethod('resetAttempts');
      return result;
    } on PlatformException catch (e) {
      log('Failed to reset attempts: ${e.message}');
      return false;
    }
  }

  /// Get remaining attempts before lockout
  Future<int> getRemainingAttempts() async {
    try {
      final int attempts =
          await _pinChannel.invokeMethod('getRemainingAttempts');
      return attempts;
    } on PlatformException catch (e) {
      log('Failed to get remaining attempts: ${e.message}');
      return 0;
    }
  }

  /// Check if the app is locked due to too many failed attempts
  Future<bool> isLocked() async {
    try {
      final bool locked = await _pinChannel.invokeMethod('isLocked');
      return locked;
    } on PlatformException catch (e) {
      log('Failed to check if app is locked: ${e.message}');
      return false;
    }
  }
}
