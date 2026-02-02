import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateStudentUserDialog extends StatefulWidget {
  const CreateStudentUserDialog({Key? key}) : super(key: key);

  @override
  State<CreateStudentUserDialog> createState() => _CreateStudentUserDialogState();
}

class _CreateStudentUserDialogState extends State<CreateStudentUserDialog> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;
  bool _loading = false;

  Future<void> _createUser() async {
    setState(() { _errorText = null; _loading = true; });
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    if ([username, password, name].any((e) => e.isEmpty)) {
      setState(() {
        _errorText = 'Barcha maydonlar majburiy.';
        _loading = false;
      });
      return;
    }
    // Kullanıcı adı benzersiz mi kontrolü
    final existing = await FirebaseFirestore.instance
        .collection('students')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      setState(() {
        _errorText = 'Ushbu foydalanuvchi nomi allaqachon olingan.';
        _loading = false;
      });
      return;
    }
    await FirebaseFirestore.instance.collection('students').add({
      'username': username,
      'password': password,
      'name': name,
      'type': 'ogrenci',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yangi O\'quvchi Foydalanuvchisini Yaratish',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Foydalanuvchi Nomi',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFFFFDE7),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Parol',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFFFFDE7),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'F.I.SH',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Color(0xFFFFFDE7),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(_errorText!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: _loading ? null : _createUser,
              child: _loading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Yaratish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ],
        ),
      ],
    );
  }
}
