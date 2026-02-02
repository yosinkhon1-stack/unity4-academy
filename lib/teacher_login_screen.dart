
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity4_academy/features/promo/promo_screen.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';
import 'main.dart';


class TeacherLoginScreen extends ConsumerStatefulWidget {
  final String? screenTitle;
  const TeacherLoginScreen({Key? key, this.screenTitle}) : super(key: key);

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  void _login() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.toLowerCase();

    // Quick Login Shortcuts
    debugPrint('Login attempt: email=$email, pass=$password'); // Added log
    if (email == 'a' && password == 'a') {
      debugPrint('Admin quick login triggered'); // Added log
      const adminEmail = 'unity4academy@gmail.com';
      ref.read(teacherEmailProvider.notifier).state = adminEmail;
      AuthStateService.saveSession(role: 'admin', id: adminEmail);
      Navigator.pushReplacementNamed(context, '/adminHome');
      return;
    }
    if (email == 'o' && password == 'o') {
      debugPrint('Teacher quick login triggered'); // Added log
      const teacherEmail = 'yosinkhon1@gmail.com';
      ref.read(teacherEmailProvider.notifier).state = teacherEmail;
      AuthStateService.saveSession(role: 'teacher', id: teacherEmail);
      Navigator.pushReplacementNamed(context, '/teacherHome');
      return;
    }
    const allowedTeacherEmails = [
      'mahmudovilyosbek924@gmail.com',
      'yosinkhon1@gmail.com',
      'turajanovayubxon95@gmail.com',
      'muhammadibrohimov123477@gmail.com',
    ];
    const allowedAdminEmails = [
      'unity4academy@gmail.com',
    ];

    if (password != 'unity42025') {
      setState(() {
        _errorMessage = 'Parol noto\'g\'ri';
      });
      return;
    }

    if (email == 'unity4academy@gmail.com') {
      ref.read(teacherEmailProvider.notifier).state = email;
      AuthStateService.saveSession(role: 'admin', id: email);
      Navigator.pushReplacementNamed(context, '/adminHome');
    } else if (allowedTeacherEmails.contains(email)) {
      ref.read(teacherEmailProvider.notifier).state = email;
      AuthStateService.saveSession(role: 'teacher', id: email);
      Navigator.pushReplacementNamed(context, '/teacherHome');
    } else {
      // Unspecified email -> Redirect to Promo/Intro Screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PromoScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.screenTitle ?? 'O\'qituvchi Kirishi')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
               decoration: const InputDecoration(labelText: 'E-pochta'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                 labelText: 'Parol',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
               child: const Text('Kirish'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
