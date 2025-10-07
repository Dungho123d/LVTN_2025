class User {
  final String id;
  final String name;
  final String email;
  // final int age;
  // final String university;
  // final String degree;
  // final String subject;
  // final String year;
  // final String avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    // required this.age,
    // required this.university,
    // required this.degree,
    // required this.subject,
    // required this.year,
    // required this.avatarUrl,
  });

  /// Tạo User từ JSON (Map)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      // age: json['age'] ?? 0,
      // university: json['university'] ?? '',
      // degree: json['degree'] ?? '',
      // subject: json['subject'] ?? '',
      // year: json['year'] ?? '',
      // avatarUrl: json['avatarUrl'] ?? '',
    );
  }

  /// Convert ngược lại thành JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      // 'age': age,
      // 'university': university,
      // 'degree': degree,
      // 'subject': subject,
      // 'year': year,
      // 'avatarUrl': avatarUrl,
    };
  }

  /// Copy với giá trị mới (immutable pattern)
  User copyWith({
    String? id,
    String? name,
    String? email,
    // int? age,
    // String? university,
    // String? degree,
    // String? subject,
    // String? year,
    // String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      // age: age ?? this.age,
      // university: university ?? this.university,
      // degree: degree ?? this.degree,
      // subject: subject ?? this.subject,
      // year: year ?? this.year,
      // avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
