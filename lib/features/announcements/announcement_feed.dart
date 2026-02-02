import 'package:flutter/material.dart';


/// E'lonni ifodalovchi model sinfi.
class Announcement {
  final String title;
  final String content;
  final DateTime date;
  final String author;

  Announcement({required this.title, required this.content, required this.date, required this.author});
}

final List<Announcement> sampleAnnouncements = [
  Announcement(
    title: 'Dars Jadvali Yangilandi',
    content: 'Yangi dars jadvali tizimga yuklandi. Iltimos, tekshirib ko\'ring.',
    date: DateTime.now().subtract(const Duration(hours: 2)),
    author: 'Admin',
  ),
  Announcement(
    title: 'Ota-onalar Majlisi',
    content: 'Ota-onalar majlisi 28-dekabr seshanba kuni soat 18:00 da bo\'lib o\'tadi.',
    date: DateTime.now().subtract(const Duration(days: 1)),
    author: 'Mudirlik',
  ),
  Announcement(
    title: 'Imtihon Natijalari E\'lon Qilindi',
    content: 'Matematika imtihon natijalari e\'lon qilindi. Tabriklaymiz!',
    date: DateTime.now().subtract(const Duration(days: 2)),
    author: 'Matematika O\'qituvchisi',
  ),
];

/// E'lonlar oqimini ko'rsatuvchi widget. Xatoliklar boshqaruvi va izohlar qo'shilgan.
class AnnouncementFeed extends StatelessWidget {
  final List<Announcement> announcements;
  const AnnouncementFeed({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      // Agar e'lonlar bo'lmasa foydalanuvchiga xabar berish.
      return const Center(child: Text('Hozircha e\'lonlar yo\'q.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = announcements[index];
        try {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.announcement, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(ann.title, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(_formatDate(ann.date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(ann.content, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text('- ${ann.author}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          // Karta yaratishda xatolik bo'lsa xabar ko'rsatish.
          return Card(
            color: Colors.red[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('E\'lon yuklanmadi: $e'),
            ),
          );
        }
      },
    );
  }

  /// Sanani formatlash.
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (now.difference(date).inDays == 0) {
      return 'Bugun';
    } else if (now.difference(date).inDays == 1) {
      return 'Kecha';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
