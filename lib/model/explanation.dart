import 'package:pocketbase/pocketbase.dart';

class Explanation {
  final String id;
  final String title;
  final double sizeMB;
  final String studySetId;
  final int? views;

  const Explanation({
    required this.id,
    required this.title,
    required this.sizeMB,
    required this.studySetId,
    this.views,
  });

  Explanation copyWith({
    String? id,
    String? title,
    double? sizeMB,
    String? studySetId,
    int? views,
  }) {
    return Explanation(
      id: id ?? this.id,
      title: title ?? this.title,
      sizeMB: sizeMB ?? this.sizeMB,
      studySetId: studySetId ?? this.studySetId,
      views: views ?? this.views,
    );
  }

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      id: (json['id'] ?? json['@id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      sizeMB: _parseDouble(json['sizeMB'] ?? json['size'] ?? json['size_mb']) ?? 0,
      studySetId: (json['studySet'] ?? json['studySetId'] ?? json['study_set'] ?? '')
          .toString(),
      views: _parseInt(json['views']),
    );
  }

  factory Explanation.fromRecord(RecordModel record) {
    return Explanation.fromJson(record.toJson());
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'sizeMB': sizeMB,
      'studySet': studySetId,
      'studySetId': studySetId,
      'views': views,
    };
    map.removeWhere((_, value) => value == null);
    return map;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
