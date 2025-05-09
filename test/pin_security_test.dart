import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:my_project/services/pin_security_service.dart';

// Generate mocks
@GenerateMocks([MethodChannel])
import 'pin_security_test.mocks.dart';

void main() {
  late PinSecurityService pinService;
  late MockMethodChannel mockMethodChannel;

  setUp(() {
    mockMethodChannel = MockMethodChannel();
    // Replace the real channel with the mock
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.hasa.app/pin'),
      (MethodCall methodCall) async {
        // Forward to our mock
        return await mockMethodChannel.invokeMethod(
          methodCall.method,
          methodCall.arguments,
        );
      },
    );

    pinService = PinSecurityService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.hasa.app/pin'),
      null,
    );
  });

  group('PIN Security Tests', () {
    test('savePin - success', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.savePin('123456');

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .called(1);
    });

    test('savePin - failure', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .thenAnswer((_) async => false);

      // Act
      final result = await pinService.savePin('123456');

      // Assert
      expect(result, false);
      verify(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .called(1);
    });

    test('savePin - platform exception', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .thenThrow(PlatformException(code: 'ERROR'));

      // Act
      final result = await pinService.savePin('123456');

      // Assert
      expect(result, false);
      verify(mockMethodChannel.invokeMethod('savePin', {'pin': '123456'}))
          .called(1);
    });

    test('verifyPin - correct PIN', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('verifyPin', {'pin': '123456'}))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.verifyPin('123456');

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('verifyPin', {'pin': '123456'}))
          .called(1);
    });

    test('verifyPin - incorrect PIN', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('verifyPin', {'pin': '654321'}))
          .thenAnswer((_) async => false);

      // Act
      final result = await pinService.verifyPin('654321');

      // Assert
      expect(result, false);
      verify(mockMethodChannel.invokeMethod('verifyPin', {'pin': '654321'}))
          .called(1);
    });

    test('isPinSet - PIN is set', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('isPinSet'))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.isPinSet();

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('isPinSet')).called(1);
    });

    test('isPinSet - PIN is not set', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('isPinSet'))
          .thenAnswer((_) async => false);

      // Act
      final result = await pinService.isPinSet();

      // Assert
      expect(result, false);
      verify(mockMethodChannel.invokeMethod('isPinSet')).called(1);
    });

    test('resetPin - success', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('resetPin'))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.resetPin();

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('resetPin')).called(1);
    });

    test('incrementAttempts - counts attempts', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('incrementAttempts'))
          .thenAnswer((_) async => 2);

      // Act
      final result = await pinService.incrementAttempts();

      // Assert
      expect(result, 2);
      verify(mockMethodChannel.invokeMethod('incrementAttempts')).called(1);
    });

    test('resetAttempts - success', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('resetAttempts'))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.resetAttempts();

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('resetAttempts')).called(1);
    });

    test('getRemainingAttempts - returns correct count', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('getRemainingAttempts'))
          .thenAnswer((_) async => 1);

      // Act
      final result = await pinService.getRemainingAttempts();

      // Assert
      expect(result, 1);
      verify(mockMethodChannel.invokeMethod('getRemainingAttempts')).called(1);
    });

    test('isLocked - locked due to too many attempts', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('isLocked'))
          .thenAnswer((_) async => true);

      // Act
      final result = await pinService.isLocked();

      // Assert
      expect(result, true);
      verify(mockMethodChannel.invokeMethod('isLocked')).called(1);
    });

    test('isLocked - not locked', () async {
      // Arrange
      when(mockMethodChannel.invokeMethod('isLocked'))
          .thenAnswer((_) async => false);

      // Act
      final result = await pinService.isLocked();

      // Assert
      expect(result, false);
      verify(mockMethodChannel.invokeMethod('isLocked')).called(1);
    });
  });
}
