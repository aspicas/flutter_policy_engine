import 'package:meta/meta.dart';

@immutable
class Policy {
  const Policy({
    required this.roleName,
    required this.allowedContent,
    this.metadata = const {},
  });

  final String roleName;
  final List<String> allowedContent;
  final Map<String, dynamic> metadata;

  Policy copyWith({
    String? roleName,
    List<String>? allowedContent,
    Map<String, dynamic>? metadata,
  }) =>
      Policy(
        roleName: roleName ?? this.roleName,
        allowedContent: allowedContent ?? this.allowedContent,
        metadata: metadata ?? this.metadata,
      );

  bool isContentAllowed(String content) => allowedContent.contains(content);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Policy &&
          roleName == other.roleName &&
          allowedContent.length == other.allowedContent.length &&
          allowedContent
              .every((content) => other.allowedContent.contains(content));

  @override
  int get hashCode => roleName.hashCode ^ allowedContent.hashCode;

  @override
  String toString() =>
      'Policy(roleName: $roleName, allowedContent: $allowedContent, metadata: $metadata)';
}
