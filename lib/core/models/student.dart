import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String username;
  final int score;
  final int absence;
  final String homework;
  final String teacherEmail;
  final String group;
  final String studentClass;

  Student({
    required this.id,
    required this.name,
    required this.username,
    required this.teacherEmail,
    required this.group,
    required this.studentClass,
    this.score = 0,
    this.absence = 0,
    this.homework = '',
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
      teacherEmail: data['teacherEmail'] ?? '',
      group: data['group'] ?? '',
      studentClass: data['class'] ?? '',
      score: data['score'] ?? 0,
      absence: data['absence'] ?? 0,
      homework: data['homework'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'teacherEmail': teacherEmail,
      'group': group,
      'class': studentClass,
      'score': score,
      'absence': absence,
      'homework': homework,
    };
  }
}
