import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/features/auth/parent_home_screen.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/shared/services/auth_state_service.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({Key? key}) : super(key: key);

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _checkStudent() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = "O'quvchi ismini kiriting");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        if (mounted) {
          AuthStateService.saveSession(role: 'parent', id: doc.id, name: name);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ParentHomeScreen(
                studentId: doc.id,
                studentName: name,
              ),
            ),
          );
        }
      } else {
        setState(() => _error = "Bunday o'quvchi topilmadi. Ism va familiyani to'g'ri kiritganingizga ishonch hosil qiling.");
      }
    } catch (e) {
      setState(() => _error = "Xatolik yuz berdi: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ota-onalar kirishi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.family_restroom, size: 80, color: Colors.purple),
            const SizedBox(height: 24),
            Text(
              "Xush kelibsiz!",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Farzandingizning o'zlashtirishini kuzatish uchun uning ism-familiyasini kiriting.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Kimning ota-onasisiz?',
                      hintText: 'Masalan: Ali Valiyev',
                      prefixIcon: Icon(Icons.child_care),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkStudent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("KIRISH", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
