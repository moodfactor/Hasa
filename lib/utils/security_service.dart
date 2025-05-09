import 'dart:io';
import 'package:flutter/services.dart';

/// A service for handling app security features.
class SecurityService {
  /// Method channel for communicating with platform-specific code
  static const MethodChannel _channel = MethodChannel('com.hasa.app/security');

  /// Enables secure mode to prevent screenshots and screen recordings.
  ///
  /// On Android, this uses FLAG_SECURE to prevent screenshots.
  /// On iOS, this uses private APIs to prevent screenshots and recordings.
  static void enableSecureMode() {
    if (Platform.isAndroid) {
      // On Android, we use the FLAG_SECURE window flag
      SystemChannels.platform
          .invokeMethod('SystemChrome.setSystemUIOverlayStyle', {
        'secure': true,
      });

      // Also try with direct method channel for newer Android versions
      try {
        _channel.invokeMethod('enableSecureMode');
      } catch (e) {
        // Fallback method if the custom method channel fails
        print('Using fallback secure mode method: $e');
      }
    } else if (Platform.isIOS) {
      // For iOS, we'll use a custom method channel
      try {
        _channel.invokeMethod('enableSecureMode');
      } catch (e) {
        print('Error enabling secure mode on iOS: $e');
      }
    }
  }

  /// Disables secure mode, allowing screenshots and recordings.
  /// Useful for specific screens where you want to allow captures.
  static void disableSecureMode() {
    if (Platform.isAndroid) {
      SystemChannels.platform
          .invokeMethod('SystemChrome.setSystemUIOverlayStyle', {
        'secure': false,
      });

      try {
        _channel.invokeMethod('disableSecureMode');
      } catch (e) {
        print('Error disabling secure mode: $e');
      }
    } else if (Platform.isIOS) {
      try {
        _channel.invokeMethod('disableSecureMode');
      } catch (e) {
        print('Error disabling secure mode on iOS: $e');
      }
    }
  }
}
