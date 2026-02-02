import 'package:flutter/material.dart';
import 'package:unity4_academy/generated/l10n.dart';
import 'package:unity4_academy/features/announcements/admin_announcement_manager.dart';
import 'package:unity4_academy/features/user/admin_student_manager.dart';
import 'package:unity4_academy/features/exam/admin_exam_manager.dart';
import 'package:unity4_academy/features/schedule/admin_schedule_manager.dart';
import 'package:unity4_academy/features/user/create_student_user_dialog.dart';
import 'package:unity4_academy/features/payments/admin_payment_screen.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';
import 'package:unity4_academy/shared/services/push_notification_service.dart';
import 'package:unity4_academy/features/teachers/admin_teacher_manager.dart';
import 'package:unity4_academy/features/schedule/sms_send_screen.dart';

class ResponsiveDashboard extends StatefulWidget {
  final String role;
  const ResponsiveDashboard({super.key, required this.role});

  @override
  State<ResponsiveDashboard> createState() => _ResponsiveDashboardState();
}

class _ResponsiveDashboardState extends State<ResponsiveDashboard> {
  @override
  void initState() {
    super.initState();
  }

  void _showCreateStudentUserDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const CreateStudentUserDialog(),
    );
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O\'quvchi foydalanuvchisi muvaffaqiyatli yaratildi.'),
            backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: theme.colorScheme.primary.withOpacity(0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(Icons.admin_panel_settings, size: 48, color: theme.colorScheme.primary),
                   ),
                   const SizedBox(height: 16),
                   Text(
                    'Admin',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                   Text(
                     'Boshqaruv Markazi',
                     style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Grid Actions
              LayoutBuilder(
                builder: (context, constraints) {
                  // Basic responsiveness: 3 columns for desktop, 2 for mobile
                  final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, 
                    children: [
                       _DashboardActionCard(
                        icon: Icons.payment,
                         label: 'To\'lovlar',
                         color: Colors.blue,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminPaymentScreen()),
                        ),
                      ),
                       _DashboardActionCard(
                        icon: Icons.announcement_rounded,
                        label: loc.announcementManagement, // E'lonlar
                        color: Colors.orange,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminAnnouncementManager()),
                        ),
                      ),
                       _DashboardActionCard(
                        icon: Icons.group,
                        label: loc.userManagement, // Foydalanuvchilar
                        color: Colors.teal,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AdminStudentManager()),
                        ),
                      ),
                       _DashboardActionCard(
                        icon: Icons.school,
                        label: loc.examManagement, // Imtihonlar
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AdminExamManager()),
                        ),
                      ),
                      _DashboardActionCard(
                        icon: Icons.calendar_month,
                        label: loc.scheduleManagement, // Dars Jadvali
                        color: Colors.redAccent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AdminScheduleManager()),
                        ),
                      ),
                      _DashboardActionCard(
                        icon: Icons.person_pin_rounded,
                        label: "O'qituvchilar",
                        color: Colors.cyan,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminTeacherManager()),
                        ),
                      ),
                      _DashboardActionCard(
                        icon: Icons.sms_rounded,
                         label: "SMS Yuborish",
                         color: Colors.pink,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SmsSendScreen()),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 48),
              Center(
                child: Text(
                  '© 2025 Unity4 Academy',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DashboardActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
