import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'students_screen.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';
import 'main.dart';

import 'package:unity4_academy/shared/services/push_notification_service.dart';
import 'package:unity4_academy/features/videos/teacher_video_manager.dart';
import 'package:unity4_academy/features/teachers/teacher_exams_screen.dart';
import 'package:unity4_academy/features/teachers/teacher_schedules_screen.dart';

class TeacherHomeScreen extends ConsumerStatefulWidget {
  const TeacherHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends ConsumerState<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      PushNotificationService.subscribeToTopic('staff_group');
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherEmail = ref.watch(teacherEmailProvider) ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('O\'QITUVCHI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await AuthStateService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              }
            },
            tooltip: "Chiqish",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xush kelibsiz,',
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'O\'qituvchi',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Cards Row
              Row(
                children: [
                  Expanded(
                    child: ModernCard(
                      backgroundGradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => StudentsScreen(teacherEmail: teacherEmail)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.group, color: theme.colorScheme.primary, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "O'quvchilarim",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernCard(
                      backgroundGradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherVideoManager()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.video_library, color: Colors.orange, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Video Darsliklar",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 2: Exams and Schedules
              Row(
                children: [
                   Expanded(
                    child: ModernCard(
                      backgroundGradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeacherExamsScreen(teacherEmail: teacherEmail)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_turned_in, color: Colors.purple, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Imtihon Natijalari",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernCard(
                      backgroundGradient: LinearGradient(
                        colors: [
                          Colors.teal.withOpacity(0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeacherSchedulesScreen(teacherEmail: teacherEmail)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_month, color: Colors.teal, size: 30),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Dars Jadvali",
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Announcements Section
              _buildSectionHeader(context, "E'lonlar", Icons.campaign_outlined),
              _buildAnnouncementsList(),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('type', isEqualTo: 'duyuru')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const ModernCard(
             child: Center(child: Text('Hali e\'lon yo\'q.', style: TextStyle(color: Colors.grey))),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            final content = data['content'] ?? data['details'] ?? data['description'] ?? '';
            final timestamp = data['date'];
            
            DateTime? date;
            if (timestamp is Timestamp) date = timestamp.toDate();
            if (timestamp is String) date = DateTime.tryParse(timestamp);
            
            final dateStr = date != null 
                ? "${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}" 
                : "";

            return ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: Text(
                          title, 
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                        ),
                      ),
                      if(dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(content, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          },
        );
      },
    );
  }


}
