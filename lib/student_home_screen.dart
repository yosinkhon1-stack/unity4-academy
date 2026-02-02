import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/shared/widgets/status_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity4_academy/core/providers/student_provider.dart';
import 'package:unity4_academy/core/models/student.dart';
import 'package:unity4_academy/features/videos/video_lessons_screen.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentHomeScreen({
    Key? key,
    required this.studentId,
  }) : super(key: key);

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  bool _hasShownWarning = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('O\'QUVCHI PANELI'), // Very distinct title
        centerTitle: true,
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
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(widget.studentId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Ma'lumot topilmadi"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String studentName = data['name'] ?? 'O\'quvchi';
          final String group = data['group'] ?? '';
          final int score = data['score'] ?? 0;
          final String teacherEmail = data['teacherEmail'] ?? '';

          // Sync provider if null
          Future.microtask(() {
            final currentProv = ref.read(currentStudentProvider);
            if (currentProv == null) {
              ref.read(currentStudentProvider.notifier).state = Student.fromFirestore(snapshot.data!);
            }
          });

          // 1. SCORE CHECK (-15 or worse)
          if (score <= -15) {
            return _buildBlockedScreen(
              context,
              "Intizom qoidalarini buzganingiz sababli darslardan vaqtinchalik chetlatildingiz.",
              "Iltimos, darslarga qaytish uchun Akademiya intizom kengashiga murojaat qiling.",
              Icons.gavel_rounded,
            );
          }

          // 2. PAYMENT CHECK (Nested StreamBuilder for payments)
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('studentId', isEqualTo: widget.studentId)
                .snapshots(),
            builder: (context, paymentSnapshot) {
              if (paymentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              bool isPaymentBlocked = false;
              bool shouldShowWarning = false;
              
              if (paymentSnapshot.hasData) {
                final now = DateTime.now();
                for (var doc in paymentSnapshot.data!.docs) {
                  final pData = doc.data() as Map<String, dynamic>;
                  final amount = pData['amount'] ?? 0;
                  final paid = pData['paidAmount'] ?? pData['paid'] ?? 0;
                  final dueDateRaw = pData['dueDate'];

                  if (paid < amount && dueDateRaw is Timestamp) {
                    final dueDate = dueDateRaw.toDate();
                    final daysOverdue = now.difference(dueDate).inDays;
                    
                    // If more than 4 days passed from due date
                    if (daysOverdue >= 4) {
                      isPaymentBlocked = true;
                      break;
                    } 
                    // Warning Condition: Due date passed (>=0) but not blocked (<4)
                    else if (daysOverdue >= 0) {
                      shouldShowWarning = true;
                    }
                  }
                }
              }

              if (isPaymentBlocked) {
                return _buildBlockedScreen(
                  context,
                  "To'lov muddati o'tganligi sababli darslardan vaqtinchalik chetlatildingiz.",
                  "Iltimos, darslarga kirish huquqini tiklash uchun qarzdorlikni bartaraf qiling yoki adminstratsiyaga murojaat qiling.",
                  Icons.payments_rounded,
                );
              }

              // Show Warning Dialog (Payment or Score)
              if (!_hasShownWarning && !isPaymentBlocked) {
                if (shouldShowWarning) {
                  _hasShownWarning = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 8),
                            Text("Diqqat!"),
                          ],
                        ),
                        content: const Text(
                          "Hurmatli o'quvchi, to'lov muddatingiz keldi. \n\nAgar to'lov o'z vaqtida amalga oshirilmasa, darslarga kirishingiz tizim tomonidan avtomatik ravishda cheklanishi mumkin."
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Tushunarli", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  });
                } else if (score <= -10) {
                   _hasShownWarning = true;
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text("Diqqat!"),
                          ],
                        ),
                        content: Text(
                          "Hurmatli o'quvchi, sizning intizom ballaringiz kritik holatda ($score). \n\nAgar ballaringiz -15 ga yetsa, darslarga kirishingiz avtomatik ravishda cheklanadi. Iltimos, akademiya qoidalariga rioya qiling."
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Tushunarli", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  });
                }
              }

              // MAIN CONTENT (When not blocked)
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModernCard(
                      backgroundGradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            studentName,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Sizning o'zlashtirishingiz",
                            style: TextStyle(color: Colors.white.withOpacity(0.9)),
                          ),
                          if (group.isNotEmpty)
                            Text(
                              "Guruh: $group",
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                      const SizedBox(height: 24),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildSimpleStatCard(
                              context,
                              "Umumiy Ball",
                              "${data['score'] ?? 0}",
                              Icons.star,
                              Colors.amber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSimpleStatCard(
                              context,
                              "Qoldirilgan darslar",
                              "${data['absence'] ?? 0}",
                              Icons.event_busy,
                              Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Teacher Section
                      _buildSectionTitle(context, "Sizning ustozingiz", Icons.person_pin_rounded),
                      _buildTeacherSection(context, teacherEmail),
                      const SizedBox(height: 24),

                      // Schedule Section
                      _buildSectionTitle(context, "Dars Jadvali", Icons.calendar_month),
                      _buildScheduleSection(group),
                      const SizedBox(height: 24),

                      // Video Lessons Section
                      _buildSectionTitle(context, "Video Darslar", Icons.video_library),
                      _buildVideoLessonsCard(context),
                      const SizedBox(height: 24),

                      // Announcements Section
                      _buildSectionTitle(context, "E'lonlar", Icons.campaign),
                      _buildAnnouncementsSection(),
                      const SizedBox(height: 24),

                      // Exam Results Section
                      _buildSectionTitle(context, "Imtihon Natijalari", Icons.school),
                      _buildExamResultsSection(widget.studentId),
                      const SizedBox(height: 24),

                      // Payments Section
                      _buildSectionTitle(context, "To'lovlar", Icons.payment),
                      _buildPaymentsSection(widget.studentId, studentName),
                      const SizedBox(height: 40),

                      TextButton(
                        onPressed: () async {
                          await AuthStateService.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
                          }
                        },
                        child: Text(
                          "TIZIMDAN CHIQISH",
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
            },
          );
        },
      ),
    );
  }

  Widget _buildBlockedScreen(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 80),
          ),
          const SizedBox(height: 40),
          Text(
            "XIZMATDAN CHEKLASH",
            style: TextStyle(
              color: Colors.red.shade100,
              letterSpacing: 4,
              fontWeight: FontWeight.w300,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Operator Contact Button
          ElevatedButton(
            onPressed: () async {
              final Uri telUri = Uri.parse('tel:+998885203030');
              if (await canLaunchUrl(telUri)) {
                await launchUrl(telUri);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.phone),
                SizedBox(width: 8),
                Text("+998 88 520 30 30", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () async {
              await AuthStateService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              }
            },
            child: Text(
              "TIZIMDAN CHIQISH",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(String group) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schedules')
          .where('group', isEqualTo: group)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const ModernCard(
            child: Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Dars jadvali mavjud emas.', style: TextStyle(color: Colors.grey)),
            )),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final timestamp = data['date'];
            DateTime? date;
            if (timestamp is Timestamp) date = timestamp.toDate();

            final dateStr = date != null ? DateFormat('dd.MM HH:mm').format(date) : "";

            return ModernCard(
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(data['title'] ?? 'Dars', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['content'] ?? data['details'] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnnouncementsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ModernCard(child: Center(child: Text("E'lonlar yo'q", style: TextStyle(color: Colors.grey))));
        }
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp?)?.toDate();

            return ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      if (date != null)
                        Text(DateFormat('dd.MM.yyyy').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(data['content'] ?? '', style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeacherSection(BuildContext context, String teacherEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teachers_info')
          .where('email', isEqualTo: teacherEmail.trim())
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        String teacherName = 'Unity4 Academy Admin';
        String teacherProficiency = 'Ustoz biriktirilmagan';
        String? teacherPhone;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final tData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          teacherName = tData['name'] ?? teacherName;
          teacherProficiency = tData['proficiency'] ?? 'O\'qituvchi';
          teacherPhone = tData['phone'];
        }

        return ModernCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 35),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(teacherProficiency, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (teacherPhone != null && teacherPhone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Message Button (iOS Style)
                    _buildCircledIconButton(
                      icon: Icons.chat_bubble,
                      color: Colors.blue,
                      onTap: () async {
                         final Uri smsUri = Uri.parse('sms:$teacherPhone');
                        if (await canLaunchUrl(smsUri)) {
                          await launchUrl(smsUri);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Call Button (iOS Style)
                    _buildCircledIconButton(
                      icon: Icons.phone,
                      color: Colors.green,
                      onTap: () async {
                        final Uri telUri = Uri.parse('tel:$teacherPhone');
                        if (await canLaunchUrl(telUri)) {
                          await launchUrl(telUri);
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildExamResultsSection(String studentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exams')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ModernCard(child: Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Hozircha natijalar yo'q", style: TextStyle(color: Colors.grey)),
          )));
        }
        return SizedBox(
          height: 350, // Increased height significantly to prevent overflow
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Imtihon';
              final result = data['result'] ?? 'N/A';
              final timestamp = data['date'];
              DateTime? date;
              if (timestamp is Timestamp) date = timestamp.toDate();
              
              final dateStr = date != null ? "${date.day}.${date.month}.${date.year}" : "";

              return SizedBox(
                width: 200, // Slightly wider
                child: ModernCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max, // Fill height
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.school, size: 18, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2, // Strict limit
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Natija:", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            result,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple),
                          ),
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const Divider(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPaymentsSection(String studentId, String studentName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: studentId)
          .orderBy('dueDate', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const ModernCard(child: Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Ma'lumot topilmadi", style: TextStyle(color: Colors.grey)),
          )));
        }
        
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0);
            final paid = (data['paidAmount'] ?? data['paid'] ?? 0);
            final isPaid = paid >= amount;
            final dueDateRaw = data['dueDate'];
            String dueDateStr = "";
            if (dueDateRaw is Timestamp) {
              dueDateStr = DateFormat('dd.MM.yyyy').format(dueDateRaw.toDate());
            }

            return ModernCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${NumberFormat('#,###').format(amount)} so'm", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Row(
                          children: [
                            if (isPaid)
                              IconButton(
                                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                tooltip: "To'lov cheki",
                                onPressed: () => _showReceiptDialog(
                                  context, 
                                  studentName, 
                                  data, 
                                  snapshot.data!.docs[index].id
                                ),
                              ),
                            StatusBadge(
                              text: isPaid ? "TO'LANGAN" : "QARZDORLIK",
                              color: isPaid ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("To'langan: ${NumberFormat('#,###').format(paid)} so'm", 
                          style: TextStyle(color: Colors.green.shade700, fontSize: 14, fontWeight: FontWeight.w500)),
                        if (dueDateStr.isNotEmpty)
                          Text("Muddat: $dueDateStr", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReceiptDialog(BuildContext context, String studentName, Map<String, dynamic> paymentData, String docId) {
    final theme = Theme.of(context);
    final amount = (paymentData['amount'] ?? 0);
    final paid = (paymentData['paidAmount'] ?? paymentData['paid'] ?? 0);
    
    final dueDateRaw = paymentData['dueDate'];
    final paidDateRaw = paymentData['paidDate'] ?? paymentData['updatedAt'];
    
    String dueDateStr = "Belgilanmagan";
    if (dueDateRaw is Timestamp) {
      dueDateStr = DateFormat('dd.MM.yyyy').format(dueDateRaw.toDate());
    }
    
    String paidDateStr = "";
    if (paidDateRaw is Timestamp) {
      paidDateStr = DateFormat('dd.MM.yyyy HH:mm').format(paidDateRaw.toDate());
    } else {
       paidDateStr = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    }

    // Generate a unique, stable receipt number based on docId and date
    final String receiptNo = "${docId.substring(0, 3).toUpperCase()}-${docId.hashCode.abs().toString().substring(0, 5)}";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.account_balance, color: Colors.white, size: 28),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "RASMIY TO'LOV CHEKI",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          "№ $receiptNo",
                          style: TextStyle(
                            color: Colors.white.withOpacity(1.0),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      "UNITY 4 ACADEMY",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Darslar uchun 1 oylik to'lov kvitansiyasi",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildReceiptRow("O'quvchi F.I.SH:", studentName, isBold: true),
                          const Divider(height: 24),
                          _buildReceiptRow("Rejadagi muddat:", dueDateStr),
                          _buildReceiptRow("To'lov sanasi:", paidDateStr, valueColor: Colors.blue.shade700),
                          const Divider(height: 24),
                          _buildReceiptRow("To'lov summasi:", "${NumberFormat('#,###').format(amount)} so'm"),
                          _buildReceiptRow("Qabul qilingan summa:", "${NumberFormat('#,###').format(paid)} so'm", isBold: true, valueColor: Colors.green.shade700),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Stamps/Verification
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Column(
                            children: [
                              Text(
                                "TO'LANDI",
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                "PAID",
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.verified_user, color: Colors.blue.shade900, size: 40),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("YOPISH", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoLessonsCard(BuildContext context) {
    return ModernCard(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoLessonsScreen()));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.ondemand_video, color: Colors.red, size: 30),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Video Darslarni Ko'rish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Mavzular bo'yicha video qo'llanmalar", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircledIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

