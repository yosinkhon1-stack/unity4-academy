import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherSchedulesScreen extends StatelessWidget {
  final String teacherEmail;

  const TeacherSchedulesScreen({Key? key, required this.teacherEmail}) : super(key: key);

  Future<void> _launchFileUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faylni ochib bo\'lmadi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dars Jadvali"),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        // Get teacher's groups first
        future: FirebaseFirestore.instance
            .collection('students')
            .where('teacherEmail', isEqualTo: teacherEmail)
            .get(),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final myGroups = studentSnapshot.data?.docs
              .map((d) => (d.data() as Map<String, dynamic>)['group'] as String?)
              .where((g) => g != null)
              .toSet() ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('schedules')
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Hali dars jadvali yo'q."));
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final group = data['group'] as String?;
                return myGroups.contains(group);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("Sizning guruhlaringiz uchun dars jadvali topilmadi."));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  final details = data['details'] ?? '';
                  final group = data['group'] ?? '';
                  final fileUrl = data['fileUrl'];
                  final timestamp = data['date'];

                  DateTime? date;
                  if (timestamp is Timestamp) date = timestamp.toDate();
                  final dateStr = date != null ? "${date.day}.${date.month}.${date.year}" : "";

                  return ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_today, color: theme.colorScheme.secondary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Guruh: $group",
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                          ],
                        ),
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(details, style: theme.textTheme.bodyMedium),
                        ],
                        if (fileUrl != null) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _launchFileUrl(context, fileUrl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_file, size: 16, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Faylni ko'rish",
                                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
