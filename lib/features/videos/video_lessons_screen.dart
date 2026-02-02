import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/core/providers/student_provider.dart';
import 'video_player_screen.dart';

class VideoLessonsScreen extends ConsumerWidget {
  const VideoLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    final theme = Theme.of(context);

    if (student == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Darslar')),
        body: const Center(child: Text("O'quvchi ma'lumotlari yuklanmoqda veya topilmadi. Iltimos, biroz kutib qayta kiring.")),
      );
    }

    if (student.group.trim().isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Darslar')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              "Siz hali hech qanday guruhga biriktirilmagansiz. Iltimos, administrator bilan bog'laning.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Darslar'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('video_lessons')
            .where('teacherEmail', isEqualTo: student.teacherEmail)
            .where('targetGroups', arrayContainsAny: [student.group.trim(), 'all'])
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Xatolik yuz berdi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.video_library_outlined, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text("Hozircha video darslar mavjud emas", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          // Convert to list and sort by status priority
          final docs = snapshot.data!.docs;
          final List<QueryDocumentSnapshot> sortedDocs = List.from(docs);
          
          sortedDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            
            final priorityA = _getStatusPriority(dataA['status'] ?? '');
            final priorityB = _getStatusPriority(dataB['status'] ?? '');
            
            if (priorityA != priorityB) {
              return priorityB.compareTo(priorityA); // Higher priority first
            }
            
            // If same priority, newest first
            final timeA = (dataA['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final timeB = (dataB['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return timeB.compareTo(timeA);
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Tavsiya';
              final statusColor = _getStatusColor(status);
              
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videoId: data['videoId'] ?? '',
                        title: data['title'] ?? '',
                        description: data['description'] ?? '',
                      ),
                    ),
                  );
                },
                child: ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CUSTOM BRANDING HEADER (instead of thumbnail)
                      Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withOpacity(0.8),
                              statusColor,
                              statusColor.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Stack(
                          children: [
                            // Back pattern
                            Positioned(
                              right: -30,
                              bottom: -30,
                              child: Icon(Icons.school, size: 150, color: Colors.white.withOpacity(0.1)),
                            ),
                            // Center Content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Unity4 Academy",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "Sinf: ${student.studentClass}",
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Icon(Icons.play_circle_filled, color: Colors.white, size: 50),
                                ],
                              ),
                            ),
                            // Status Badge
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // INFO SECTION
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Nomsiz dars',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['description'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.group_work, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      (data['targetGroups'] as List?)?.contains('all') == true 
                                        ? "Barcha uchun" 
                                        : "Guruh: ${student.group}",
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatDate(data['createdAt']),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _getStatusPriority(String status) {
    switch (status) {
      case 'Majburiy': return 5;
      case 'Muhim': return 4;
      case 'Nazorat': return 3;
      case 'Yangi': return 2;
      case 'Tavsiya': return 1;
      default: return 0;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Majburiy': return Colors.red.shade600;
      case 'Muhim': return Colors.orange.shade700;
      case 'Nazorat': return Colors.purple.shade600;
      case 'Yangi': return Colors.blue.shade600;
      case 'Tavsiya': return Colors.green.shade600;
      default: return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}.${date.month}.${date.year}";
    }
    return "";
  }
}
