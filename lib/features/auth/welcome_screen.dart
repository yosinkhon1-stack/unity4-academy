import 'package:flutter/material.dart';
import 'package:unity4_academy/student_login_screen.dart';
import 'package:unity4_academy/teacher_login_screen.dart';
import 'package:unity4_academy/features/auth/parent_login_screen.dart';
import 'package:unity4_academy/features/promo/promo_screen.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/core/theme/app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _showOptions = false;

  void _handleRoleSelection(String role) {
    if (role == 'admin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherLoginScreen(screenTitle: 'Admin')),
      );
    } else if (role == 'teacher') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TeacherLoginScreen(screenTitle: "O'qituvchi")),
      );
    } else if (role == 'parent') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentLoginScreen()),
      );
    } else if (role == 'student') {
      // Students go to User/Pass Login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
      );
    } else if (role == 'guest') {
      // Guests go to Promo
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PromoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spacer equivalent (flexible space before logo)
                      const SizedBox(height: 48), 
                      // HERO LOGO
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 200, 
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      if (!_showOptions)
                        // INITIAL ENTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showOptions = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGold,
                              foregroundColor: AppColors.textLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "KIRISH",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        )
                      else
                        // ROLE OPTIONS
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Siz kimsiz?",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                             const SizedBox(height: 16),
                            _buildRoleButton("Adminman", Icons.admin_panel_settings, () => _handleRoleSelection('admin')),
                            const SizedBox(height: 12),
                            _buildRoleButton("O'qituvchiman", Icons.school, () => _handleRoleSelection('teacher')),
                            const SizedBox(height: 12),
                            _buildRoleButton("O'quvchiman", Icons.person, () => _handleRoleSelection('student')),
                            const SizedBox(height: 12),
                            _buildRoleButton("Ota-Onaman", Icons.family_restroom, () => _handleRoleSelection('parent')),
                            const SizedBox(height: 12),
                            _buildRoleButton("A'zo emasman", Icons.public, () => _handleRoleSelection('guest')),
                            
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showOptions = false;
                                });
                              },
                              child: const Text("Orqaga", style: TextStyle(color: Colors.grey)),
                            )
                          ],
                        ),
                      
                      const SizedBox(height: 48), 
                      // Footer
                      const Text("Unity4 Academy © 2025", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRoleButton(String label, IconData icon, VoidCallback onTap) {
    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryGold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
