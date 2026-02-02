import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'core/models/student.dart';

class StudentsScreen extends ConsumerWidget {
  // State for selected group
  static final _groupProvider = StateProvider<String?>((ref) => null);

  Future<void> assignHomework(BuildContext context, String studentId, String currentHomework) async {
    final controller = TextEditingController(text: currentHomework);
    final theme = Theme.of(context);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text("Uy Vazifasi", style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Uy vazifasi matni",
          ),
          style: theme.textTheme.bodyMedium,
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Saqla"),
          ),
        ],
      ),
    );
    if (result != null && result != currentHomework) {
      await FirebaseFirestore.instance.collection('students').doc(studentId).update({'homework': result});
    }
  }

  Future<void> updateStudentScore(String studentId, int newScore) async {
    await FirebaseFirestore.instance.collection('students').doc(studentId).update({'score': newScore});
  }

  Future<void> updateStudentAbsence(String studentId, int newAbsence) async {
    await FirebaseFirestore.instance.collection('students').doc(studentId).update({'absence': newAbsence});
  }

  final String teacherEmail;
  const StudentsScreen({Key? key, required this.teacherEmail}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroup = ref.watch(_groupProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("O'quvchilarim"),
        actions: [
          if (selectedGroup != null)
            IconButton(
              icon: const Icon(Icons.playlist_add_check),
              tooltip: "Bu guruhga uy vazifasi berish",
              onPressed: () async {
                final controller = TextEditingController();
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('"$selectedGroup" Guruhi', style: theme.textTheme.titleLarge),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Guruhdagi barcha o'quvchilarga uy vazifasi yuborilsinmi?"),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(hintText: "Uy vazifasi matni"),
                          maxLines: 2,
                          autofocus: true,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Bekor qilish"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        child: const Text("Yubor"),
                      ),
                    ],
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  // Get all students in the selected group
                  final query = await FirebaseFirestore.instance
                      .collection('students')
                      .where('teacherEmail', isEqualTo: teacherEmail)
                      .where('group', isEqualTo: selectedGroup)
                      .get();
                  for (final doc in query.docs) {
                    await doc.reference.update({'homework': result});
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$selectedGroup" guruhiga vazifa berildi.')),
                    );
                  }
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Group Management Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                 BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('teacherEmail', isEqualTo: teacherEmail)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const LinearProgressIndicator();
                      final groups = snapshot.data!.docs
                          .map((doc) => (doc.data() as Map<String, dynamic>)['group'] as String? ?? '')
                          .toSet()
                          .where((g) => g.isNotEmpty)
                          .toList();
                          
                      return DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGroup,
                          hint: Text('Guruhni Filtrlash', style: theme.textTheme.bodyLarge),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                          items: [
                            DropdownMenuItem<String>(
                              value: null, 
                              child: Text('Barcha Guruhlar', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary))
                            ),
                            ...groups.map((g) => DropdownMenuItem<String>(value: g, child: Text(g)))
                          ],
                          onChanged: (val) => ref.read(_groupProvider.notifier).state = val,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Students List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .where('teacherEmail', isEqualTo: teacherEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text("Hech qanday o'quvchi topilmadi.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                var students = snapshot.data!.docs.map((doc) => Student.fromFirestore(doc)).toList();
                if (selectedGroup != null) {
                  students = students.where((s) => s.group == selectedGroup).toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('payments')
                          .where('studentId', isEqualTo: student.id)
                          .snapshots(),
                      builder: (context, paymentSnapshot) {
                        bool isPaymentBlocked = false;
                        if (paymentSnapshot.hasData) {
                          final now = DateTime.now();
                          for (var doc in paymentSnapshot.data!.docs) {
                            final pData = doc.data() as Map<String, dynamic>;
                            final amount = pData['amount'] ?? 0;
                            final paid = pData['paidAmount'] ?? pData['paid'] ?? 0;
                            final dueDateRaw = pData['dueDate'];

                            if (paid < amount && dueDateRaw is Timestamp) {
                              final dueDate = dueDateRaw.toDate();
                              if (now.difference(dueDate).inDays >= 4) {
                                isPaymentBlocked = true;
                                break;
                              }
                            }
                          }
                        }

                        bool isScoreBlocked = student.score <= -15;
                        bool isBlocked = isScoreBlocked || isPaymentBlocked;

                        // Visual styling for blocked state
                        final cardColor = isBlocked ? Colors.red.shade50 : null;
                        final borderColor = isBlocked ? Colors.red : Colors.transparent;
                        
                        // Status color for score indicator
                        Color scoreColor;
                        if (student.score <= -15) scoreColor = Colors.red;
                        else if (student.score <= -10) scoreColor = Colors.orange;
                        else if (student.score <= 10) scoreColor = Colors.amber; 
                        else scoreColor = Colors.green;

                        return ModernCard(
                          backgroundColor: cardColor,
                          child: Container(
                            decoration: BoxDecoration(
                              border: isBlocked ? Border.all(color: Colors.red, width: 2) : null,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                if (isBlocked)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    ),
                                    child: const Text(
                                      "DARSGA KIRISHI TAQIQLANGAN",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0), // Standard padding inside the card
                                  child: Column(
                                    children: [
                                      // Header: Name & Group + Homework Action
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isBlocked ? Colors.red.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold, 
                                                  color: isBlocked ? Colors.red : theme.colorScheme.primary
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.name, 
                                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                                                ),
                                                if(student.group.isNotEmpty)
                                                  Text(
                                                    student.group,
                                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.edit_note, color: theme.colorScheme.primary),
                                            tooltip: "Vazifa Yuborish",
                                            onPressed: () async {
                                              await assignHomework(context, student.id, student.homework);
                                            },
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      
                                      // Stats Controls
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          // Score Control
                                          Column(
                                            children: [
                                              Text("Ball", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                                              const SizedBox(height: 4),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color:  theme.colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: scoreColor.withOpacity(0.5)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    _buildControlButton(icon: Icons.remove, onTap: () async {
                                                      await updateStudentScore(student.id, student.score - 1);
                                                    }),
                                                    Container(
                                                      constraints: const BoxConstraints(minWidth: 30),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        '${student.score}',
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: scoreColor),
                                                      ),
                                                    ),
                                                    _buildControlButton(icon: Icons.add, onTap: () async {
                                                       await updateStudentScore(student.id, student.score + 1);
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          
                                          // Absence Control
                                          Column(
                                            children: [
                                               Text("Qoldirdi", style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
                                               const SizedBox(height: 4),
                                               Container(
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surface,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    _buildControlButton(icon: Icons.remove, onTap: () async {
                                                       await updateStudentAbsence(student.id, student.absence - 1);
                                                    }),
                                                    Container(
                                                      constraints: const BoxConstraints(minWidth: 30),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        '${student.absence}', 
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                                      ),
                                                    ),
                                                    _buildControlButton(icon: Icons.add, onTap: () async {
                                                      await updateStudentAbsence(student.id, student.absence + 1);
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      
                                      if(student.homework.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.assignment_outlined, size: 16, color: Colors.blue),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  student.homework,
                                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue.shade800),
                                                  maxLines: 1, 
                                                  overflow: TextOverflow.ellipsis
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
       borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
