import 'package:flutter/services.dart';
import 'package:flutter_policy_engine/src/core/interfaces/i_policy_storage.dart';
import 'package:flutter_policy_engine/src/utils/json_handler.dart';
import 'package:flutter_policy_engine/src/utils/log_handler.dart';

/// A policy storage implementation that loads policies from Flutter assets.
///
/// This class implements the [IPolicyStorage] interface to provide policy
/// storage functionality using Flutter's asset system. It loads policies
/// from JSON files stored in the app's assets directory.
///
/// The asset file should contain a valid JSON object with policy definitions.
/// If the asset file cannot be loaded or parsed, an empty map is returned
/// and an error is logged.
///
/// Example usage:
/// ```dart
/// final storage = AssetPolicyStorage(assetPath: 'assets/policies.json');
/// final policies = await storage.loadPolicies();
/// ```
class AssetPolicyStorage implements IPolicyStorage {
  /// Creates an [AssetPolicyStorage] instance.
  ///
  /// The [assetPath] parameter specifies the path to the JSON asset file
  /// relative to the app's assets directory (e.g., 'assets/policies.json').
  ///
  /// Throws an [ArgumentError] if [assetPath] is null or empty.
  AssetPolicyStorage({
    required String assetPath,
  }) : _assetPath = assetPath {
    if (assetPath.isEmpty) {
      throw ArgumentError('Asset path cannot be empty', 'assetPath');
    }
  }

  /// The path to the asset file containing the policies.
  final String _assetPath;

  /// Clears all stored policies.
  ///
  /// This method is not implemented for asset-based storage since assets
  /// are read-only. Attempting to call this method will throw an
  /// [UnimplementedError].
  ///
  /// Throws [UnimplementedError] - Asset storage is read-only.
  @override
  Future<void> clearPolicies() {
    // TODO: implement clearPolicies
    throw UnimplementedError();
  }

  /// Loads policies from the specified asset file.
  ///
  /// Reads the JSON content from the asset file specified in the constructor
  /// and parses it into a [Map&lt;String, dynamic&gt;]. The JSON should contain
  /// policy definitions in a structured format.
  ///
  /// The method performs the following operations:
  /// 1. Loads the JSON string from the asset file using [rootBundle.loadString]
  /// 2. Parses the JSON string into a [Map&lt;String, dynamic&gt;] using [JsonHandler.parseJsonString]
  /// 3. Returns the parsed policies map
  ///
  /// **Error Handling:**
  /// - If the asset file cannot be found or read, a [PlatformException] is thrown
  /// - If the JSON content is malformed, a [JsonParseException] is thrown
  /// - If any other error occurs during loading or parsing, the error is caught,
  ///   logged via [LogHandler.error], and an empty map is returned
  ///
  /// **Returns:** A [Map&lt;String, dynamic&gt;] containing the loaded policies.
  /// Returns an empty map if the asset file cannot be loaded or parsed.
  ///
  /// **Example:**
  /// ```dart
  /// final storage = AssetPolicyStorage(assetPath: 'assets/policies.json');
  /// final policies = await storage.loadPolicies();
  /// print('Loaded ${policies.length} policies');
  /// ```
  ///
  /// **Throws:**
  /// - [PlatformException] if the asset file cannot be found or read
  /// - [JsonParseException] if the JSON content is malformed
  @override
  Future<Map<String, dynamic>> loadPolicies() async {
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

  /// Saves policies to storage.
  ///
  /// This method is not implemented for asset-based storage since assets
  /// are read-only. Attempting to call this method will throw an
  /// [UnimplementedError].
  ///
  /// Throws [UnimplementedError] - Asset storage is read-only.
  @override
  Future<void> savePolicies(Map<String, dynamic> policies) {
    // TODO: implement savePolicies
    throw UnimplementedError();
  }
}
