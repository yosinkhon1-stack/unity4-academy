import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';

class TeacherExamsScreen extends StatelessWidget {
  final String teacherEmail;

  const TeacherExamsScreen({Key? key, required this.teacherEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Imtihon Natijalari"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We attempt to filter by teacherEmail first (for new exams)
        // For old exams, we would need a more complex query or client-side filter.
        // Let's use a query that handles both if possible, or just the new ones and we'll see.
        // Actually, fetching all and filtering is safer for completeness if the list isn't huge.
        stream: FirebaseFirestore.instance
            .collection('exams')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Hali imtihon natijalari yo'q."));
          }

          return FutureBuilder<QuerySnapshot>(
            // Fetch the teacher's students to verify ownership for older records
            future: FirebaseFirestore.instance
                .collection('students')
                .where('teacherEmail', isEqualTo: teacherEmail)
                .get(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final myStudentIds = studentSnapshot.data?.docs.map((d) => d.id).toSet() ?? {};
              
              // Filter docs: either has teacherEmail matching OR studentId is in our list
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final docTeacherEmail = data['teacherEmail'];
                if (docTeacherEmail == teacherEmail) return true;
                
                final studentId = data['studentId'];
                return myStudentIds.contains(studentId);
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("Sizga tegishli imtihon natijalari topilmadi."));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? 'Imtihon';
                  final result = data['result'] ?? 'N/A';
                  final timestamp = data['date'];
                  final studentId = data['studentId'] ?? '';
                  
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
                            Icon(Icons.assignment_turned_in, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text("O'quvchi: ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            Text(studentId, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Natija:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                result,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ),
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
