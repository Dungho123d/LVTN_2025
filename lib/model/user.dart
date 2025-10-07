import 'package:pocketbase/pocketbase.dart';

class User {
  final String id;
  final String name;
  final int age;
  final String university;
  final String degree;
  final String subject;
  final String year;
  final String avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.age,
    required this.university,
    required this.degree,
    required this.subject,
    required this.year,
    required this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? name,
    int? age,
    String? university,
    String? degree,
    String? subject,
    String? year,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      university: university ?? this.university,
      degree: degree ?? this.degree,
      subject: subject ?? this.subject,
      year: year ?? this.year,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['@id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['username'] ?? '').toString(),
      age: _parseInt(json['age']) ?? 0,
      university: (json['university'] ?? json['school'] ?? '').toString(),
      degree: (json['degree'] ?? json['major'] ?? '').toString(),
      subject: (json['subject'] ?? json['focus'] ?? '').toString(),
      year: (json['year'] ?? json['academic_year'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? '').toString(),
    );
  }

  factory User.fromRecord(RecordModel record) {
    return User.fromJson(record.toJson());
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'university': university,
      'degree': degree,
      'subject': subject,
      'year': year,
      'avatarUrl': avatarUrl,
    };
    map.removeWhere((_, value) => value == null);
    return map;
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
