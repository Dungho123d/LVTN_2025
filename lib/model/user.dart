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
}
