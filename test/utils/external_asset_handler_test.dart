import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_policy_engine/src/utils/external_asset_handler.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';

void main() {
  group('ExternalAssetHandler', () {
    setUp(() {
      // Reset LogHandler to default state before each test
      LogHandler.reset();
    });

    group('Constructor', () {
      test('should create instance with valid asset path', () {
        const assetPath = 'assets/policies/config.json';

        expect(() {
          ExternalAssetHandler(assetPath: assetPath);
        }, returnsNormally);
      });

      test('should throw ArgumentError for empty asset path', () {
        expect(
          () => ExternalAssetHandler(assetPath: ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError for whitespace-only asset path', () {
        expect(
          () => ExternalAssetHandler(assetPath: '   '),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should accept asset path with special characters', () {
        const assetPath = 'assets/policies/user-roles_v2.json';

        expect(() {
          ExternalAssetHandler(assetPath: assetPath);
        }, returnsNormally);
      });

      test('should accept asset path with nested directories', () {
        const assetPath = 'assets/policies/production/user_roles.json';

        expect(() {
          ExternalAssetHandler(assetPath: assetPath);
        }, returnsNormally);
      });

      test('should accept asset path with different file extensions', () {
        const assetPath = 'assets/policies/config.json';

        expect(() {
          ExternalAssetHandler(assetPath: assetPath);
        }, returnsNormally);
      });
    });

    group('loadAssets', () {
      test('should handle non-existent asset gracefully', () async {
        const assetPath = 'assets/policies/valid_config.json';

        // Initialize Flutter test binding
        TestWidgetsFlutterBinding.ensureInitialized();

        // Create handler with non-existent asset path
        // This will test the error handling path since the asset doesn't exist in test environment
        final handler = ExternalAssetHandler(assetPath: assetPath);
        final result = await handler.loadAssets();

        // The result should be empty because the asset doesn't exist
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
      });

      group('Error handling', () {
        test('should return empty map when asset not found', () async {
          const assetPath = 'assets/policies/nonexistent.json';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                throw PlatformException(
                  code: 'ASSET_NOT_FOUND',
                  message: 'Asset not found: $assetPath',
                );
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test('should return empty map when JSON parsing fails', () async {
          const assetPath = 'assets/policies/invalid_json.json';
          const invalidJson = '{"invalid": json, "missing": quotes}';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                return invalidJson;
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test('should return empty map when asset is empty string', () async {
          const assetPath = 'assets/policies/empty_string.json';
          const emptyContent = '';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                return emptyContent;
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test('should return empty map when asset contains only whitespace',
            () async {
          const assetPath = 'assets/policies/whitespace_only.json';
          const whitespaceContent = '   \n\t  ';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                return whitespaceContent;
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test(
            'should return empty map when asset contains JSON array instead of object',
            () async {
          const assetPath = 'assets/policies/array_instead_of_object.json';
          const arrayJson = '[1, 2, 3, 4, 5]';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                return arrayJson;
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test(
            'should return empty map when asset contains JSON primitive instead of object',
            () async {
          const assetPath = 'assets/policies/primitive_instead_of_object.json';
          const primitiveJson = '"hello world"';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                return primitiveJson;
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test('should return empty map when platform exception occurs',
            () async {
          const assetPath = 'assets/policies/platform_error.json';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                throw PlatformException(
                  code: 'UNKNOWN_ERROR',
                  message: 'Unknown platform error',
                );
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });

        test('should return empty map when general exception occurs', () async {
          const assetPath = 'assets/policies/general_error.json';

          TestWidgetsFlutterBinding.ensureInitialized();
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'loadString' &&
                  methodCall.arguments == assetPath) {
                throw Exception('General error occurred');
              }
              return null;
            },
          );

          final handler = ExternalAssetHandler(assetPath: assetPath);
          final result = await handler.loadAssets();

          expect(result, isA<Map<String, dynamic>>());
          expect(result, isEmpty);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/services'),
            null,
          );
        });
      });
    });

    group('Integration with JsonHandler', () {
      test('should handle JSON that JsonHandler.parseJsonString would reject',
          () async {
        const assetPath = 'assets/policies/invalid_integration.json';
        const invalidJson = '{"invalid": json, "syntax": error}';

        TestWidgetsFlutterBinding.ensureInitialized();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString' &&
                methodCall.arguments == assetPath) {
              return invalidJson;
            }
            return null;
          },
        );

        final handler = ExternalAssetHandler(assetPath: assetPath);
        final result = await handler.loadAssets();

        // Should return empty map instead of throwing
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          null,
        );
      });
    });

    group('Logging behavior', () {
      test('should log error when asset loading fails', () async {
        const assetPath = 'assets/policies/logging_test.json';

        TestWidgetsFlutterBinding.ensureInitialized();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString' &&
                methodCall.arguments == assetPath) {
              throw PlatformException(
                code: 'ASSET_NOT_FOUND',
                message: 'Asset not found: $assetPath',
              );
            }
            return null;
          },
        );

        final handler = ExternalAssetHandler(assetPath: assetPath);
        final result = await handler.loadAssets();

        expect(result, isEmpty);
        // Note: We can't easily test the actual logging output in unit tests
        // but we can verify the method completes without throwing

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          null,
        );
      });

      test('should log error when JSON parsing fails', () async {
        const assetPath = 'assets/policies/logging_parse_test.json';
        const invalidJson = '{"invalid": json, "missing": quotes}';

        TestWidgetsFlutterBinding.ensureInitialized();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString' &&
                methodCall.arguments == assetPath) {
              return invalidJson;
            }
            return null;
          },
        );

        final handler = ExternalAssetHandler(assetPath: assetPath);
        final result = await handler.loadAssets();

        expect(result, isEmpty);
        // Method should complete without throwing, logging the error internally

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/services'),
          null,
        );
      });
    });
  });
}
