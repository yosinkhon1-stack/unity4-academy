import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String type; // 'duyuru', 'sinav', 'sonuc', 'ders_programi'

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'duyuru',
    );
  }
}
