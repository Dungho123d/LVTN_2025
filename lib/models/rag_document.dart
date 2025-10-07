import 'package:flutter/foundation.dart';

@immutable
class RagDocument {
  final String id;
  final String name;
  final int pageCount;
  final DateTime uploadedAt;

  const RagDocument({
    required this.id,
    required this.name,
    required this.pageCount,
    required this.uploadedAt,
  });

  String get uploadedLabel {
    final day = uploadedAt.day.toString().padLeft(2, '0');
    final month = uploadedAt.month.toString().padLeft(2, '0');
    final year = uploadedAt.year.toString();
    return '$day/$month/$year';
  }

  RagDocument copyWith({
    String? id,
    String? name,
    int? pageCount,
    DateTime? uploadedAt,
  }) {
    return RagDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      pageCount: pageCount ?? this.pageCount,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
