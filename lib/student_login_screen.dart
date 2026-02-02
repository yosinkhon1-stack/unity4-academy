import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/models/student.dart';
import 'core/providers/student_provider.dart' show currentStudentProvider;
import 'package:unity4_academy/shared/services/auth_state_service.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() { _errorMessage = null; _loading = true; });
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Foydalanuvchi nomi va parol kiritilishi shart.';
        _loading = false;
      });
      return;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        // Successful login
        final doc = query.docs.first;
        final studentId = doc.id;
        final studentData = doc.data();
        
        // Create Student model
        final student = Student(
          id: studentId,
          name: studentData['name'] ?? '',
          username: studentData['username'] ?? '',
          teacherEmail: studentData['teacherEmail'] ?? '',
          group: (studentData['group'] as String? ?? '').trim(),
          studentClass: studentData['class'] ?? '',
          score: studentData['score'] ?? 0,
          absence: studentData['absence'] ?? 0,
          homework: studentData['homework'] ?? '',
        );
        
        // Correctly update the provider using ref
        ref.read(currentStudentProvider.notifier).state = student;
        AuthStateService.saveSession(role: 'student', id: studentId, name: student.name);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentHomeScreen(studentId: studentId),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Foydalanuvchi nomi yoki parol noto\'g\'ri.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik yuz berdi: $e';
      });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O\'quvchi Kirishi')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Foydalanuvchi Nomi'),
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
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text('Kirish'),
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
