import 'package:flutter/foundation.dart';

@immutable
class RagDocument {
  final String id;
  final String name;
  final int chunkCount;
  final DateTime? uploadedAt;
  final int approxTokens;
  final Map<String, int> qualityTiers;
  final int sizeBytes;

  const RagDocument({
    required this.id,
    required this.name,
    required this.chunkCount,
    this.uploadedAt,
    this.approxTokens = 0,
    this.qualityTiers = const {},
    this.sizeBytes = 0,
  });

  String get uploadedLabel {
    final ts = uploadedAt;
    if (ts == null) {
      return 'không rõ';
    }
    final day = ts.day.toString().padLeft(2, '0');
    final month = ts.month.toString().padLeft(2, '0');
    final year = ts.year.toString();
    return '$day/$month/$year';
  }

  String get chunkLabel =>
      chunkCount == 1 ? '1 đoạn ngữ cảnh' : '$chunkCount đoạn ngữ cảnh';

  factory RagDocument.fromJson(Map<String, dynamic> json) {
    DateTime? uploadedAt;
    final uploadedRaw = json['uploaded_at'];
    if (uploadedRaw is String && uploadedRaw.isNotEmpty) {
      uploadedAt = DateTime.tryParse(uploadedRaw)?.toLocal();
    }

    final quality = <String, int>{};
    final rawQuality = json['quality_tiers'];
    if (rawQuality is Map) {
      rawQuality.forEach((key, value) {
        if (value is num) {
          quality[key.toString()] = value.toInt();
        }
      });
    }

    String? id = json['id'] as String?;
    final fallbackName = json['source'] as String? ?? json['name'] as String?;
    id ??= fallbackName ?? 'doc-${DateTime.now().millisecondsSinceEpoch}';

    final chunkCountRaw =
        json['chunk_count'] ?? json['chunks'] ?? json['added_chunks'];
    final chunkCount = chunkCountRaw is num ? chunkCountRaw.toInt() : 0;

    return RagDocument(
      id: id,
      name: json['name'] as String? ?? fallbackName ?? 'Không rõ tài liệu',
      chunkCount: chunkCount,
      approxTokens: (json['approx_tokens'] as num?)?.toInt() ?? 0,
      qualityTiers: quality,
      uploadedAt: uploadedAt,
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    );
  }

  RagDocument copyWith({
    String? id,
    String? name,
    int? chunkCount,
    DateTime? uploadedAt,
    int? approxTokens,
    Map<String, int>? qualityTiers,
    int? sizeBytes,
  }) {
    return RagDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      chunkCount: chunkCount ?? this.chunkCount,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      approxTokens: approxTokens ?? this.approxTokens,
      qualityTiers: qualityTiers ?? this.qualityTiers,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}
