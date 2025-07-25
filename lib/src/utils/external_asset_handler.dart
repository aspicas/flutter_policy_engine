import 'package:flutter/services.dart';
import 'package:flutter_policy_engine/src/utils/json_handler.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';

/// Handles loading and parsing of external asset files for policy configuration.
///
/// This class provides a convenient way to load JSON policy files from Flutter assets
/// and parse them into a structured format. It includes error handling and logging
/// for robust asset loading operations.
///
/// ## Usage
///
/// ```dart
/// // Initialize with asset path
/// final assetHandler = ExternalAssetHandler(
///   assetPath: 'assets/policies/config.json',
/// );
///
/// // Load and parse the asset
/// final policies = await assetHandler.loadAssets();
/// ```
///
/// ## Error Handling
///
/// The class automatically handles asset loading errors and returns an empty map
/// if the asset cannot be loaded or parsed. All errors are logged for debugging.
class ExternalAssetHandler {
  /// Creates an [ExternalAssetHandler] instance.
  ///
  /// The [assetPath] parameter specifies the path to the JSON asset file within
  /// the Flutter assets directory. This path should be relative to the assets
  /// folder and must be declared in the `pubspec.yaml` file.
  ///
  /// ## Parameters
  ///
  /// * [assetPath] - The path to the JSON asset file (e.g., 'assets/policies/config.json')
  ///
  /// ## Throws
  ///
  /// * [ArgumentError] - If [assetPath] is empty or null
  ///
  /// ## Example
  ///
  /// ```dart
  /// final handler = ExternalAssetHandler(
  ///   assetPath: 'assets/policies/user_roles.json',
  /// );
  /// ```
  ExternalAssetHandler({
    required String assetPath,
  }) : _assetPath = assetPath {
    if (assetPath.isEmpty) {
      throw ArgumentError('Asset path cannot be empty', 'assetPath');
    }
  }

  /// The path to the asset file.
  final String _assetPath;

  /// Loads and parses the JSON asset file.
  ///
  /// This method asynchronously loads the JSON file from the specified asset path
  /// and parses it into a [Map<String, dynamic>]. If the asset cannot be loaded
  /// or parsed, an empty map is returned and the error is logged.
  ///
  /// ## Returns
  ///
  /// A [Future<Map<String, dynamic>>] containing the parsed JSON data.
  /// Returns an empty map if loading or parsing fails.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final assetHandler = ExternalAssetHandler(
  ///   assetPath: 'assets/policies/config.json',
  /// );
  ///
  /// final policies = await assetHandler.loadAssets();
  /// if (policies.isNotEmpty) {
  ///   // Process the loaded policies
  ///   print('Loaded ${policies.length} policies');
  /// } else {
  ///   print('No policies loaded or asset not found');
  /// }
  /// ```
  ///
  /// ## Error Handling
  ///
  /// The method catches and logs the following types of errors:
  /// * Asset not found errors
  /// * JSON parsing errors
  /// * File system access errors
  ///
  /// All errors are logged using [LogHandler.error] for debugging purposes.
  Future<Map<String, dynamic>> loadAssets() async {
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      return JsonHandler.parseJsonString(jsonString);
    } catch (e) {
      LogHandler.error(
        'Failed to load policies from asset: $_assetPath',
        error: e,
      );
      // Return an empty map with the correct type to satisfy the return type
      return <String, dynamic>{};
    }
  }
}
