import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_student_user_dialog.dart';

class AdminUserManager extends StatefulWidget {
  const AdminUserManager({super.key});

  @override
  State<AdminUserManager> createState() => _AdminUserManagerState();
}

class _AdminUserManagerState extends State<AdminUserManager> {
      void _showCreateStudentUserDialog() async {
        final result = await showDialog(
          context: context,
          builder: (context) => const CreateStudentUserDialog(),
        );
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('O\'quvchi foydalanuvchisi muvaffaqiyatli yaratildi.'), backgroundColor: Colors.green),
          );
          setState(() {});
        }
      }
    Future<void> _editStudentDialog(String docId, Map<String, dynamic> data) async {
      final nameController = TextEditingController(text: data['name'] ?? '');
      final classController = TextEditingController(text: data['class'] ?? '');
      final groupController = TextEditingController(text: data['group'] ?? '');
      final teacherController = TextEditingController(text: data['teacherEmail'] ?? '');
      String? errorText;
      bool isSaving = false;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('O\'quvchi Ma\'lumotlarini Tahrirlash'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'O\'quvchi Ismi',
                        errorText: errorText != null && nameController.text.trim().isEmpty ? 'Bu maydon majburiy' : null,
                      ),
                    ),
                    TextField(
                      controller: classController,
                      decoration: InputDecoration(
                        labelText: 'Sinf',
                        errorText: errorText != null && classController.text.trim().isEmpty ? 'Bu maydon majburiy' : null,
                      ),
                    ),
                    TextField(
                      controller: groupController,
                      decoration: InputDecoration(
                        labelText: 'Guruh',
                        errorText: errorText != null && groupController.text.trim().isEmpty ? 'Bu maydon majburiy' : null,
                      ),
                    ),
                    TextField(
                      controller: teacherController,
                      decoration: InputDecoration(
                        labelText: 'O\'qituvchi E-pochtasi',
                        errorText: errorText != null && teacherController.text.trim().isEmpty ? 'Bu maydon majburiy' : null,
                      ),
                    ),
                    if (errorText != null && errorText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(errorText, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Bekor qilish'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() => errorText = null);
                          if (nameController.text.trim().isEmpty ||
                              classController.text.trim().isEmpty ||
                              groupController.text.trim().isEmpty ||
                              teacherController.text.trim().isEmpty) {
                            setState(() => errorText = 'Barcha maydonlarni to\'ldiring.');
                            return;
                          }
                          setState(() => isSaving = true);
                          await FirebaseFirestore.instance.collection('users').doc(docId).update({
                            'name': nameController.text.trim(),
                            'class': classController.text.trim(),
                            'group': groupController.text.trim(),
                            'teacherEmail': teacherController.text.trim(),
                          });
                          setState(() => isSaving = false);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('O\'quvchi ma\'lumotlari yangilandi.'), backgroundColor: Colors.green),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Saqlash'),
                ),
              ],
            ),
          );
        },
      );
      setState(() {});
    }
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';
  static const List<String> validRoles = ['admin', 'teacher', 'parent', 'student'];

  Future<void> _addUser() async {
    // Sadece Firestore'a kullanıcı ekler, auth ile otomatik giriş eklenmez
    if (_emailController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').add({
      'email': _emailController.text,
      'role': _selectedRole,
    });
    _emailController.clear();
    _passwordController.clear();
    setState(() {});
  }

  Future<void> _deleteUser(String docId) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).delete();
    setState(() {});
  }

  Future<void> _updateRole(String docId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({'role': newRole});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('O\'quvchilarni Boshqarish')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Card(
                elevation: 6,
                color: Colors.orange[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  onTap: _showCreateStudentUserDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 40.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_add, color: Colors.deepOrange, size: 40),
                        SizedBox(width: 18),
                        Text('Foydalanuvchi Yaratish', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-pochta'),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: validRoles.contains(_selectedRole) ? _selectedRole : 'student',
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'teacher', child: Text('O\'qituvchi')),
                    DropdownMenuItem(value: 'parent', child: Text('Ota-ona')),
                    DropdownMenuItem(value: 'student', child: Text('O\'quvchi')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v ?? 'student'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addUser,
                  child: const Text('Qo\'shish'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final data = user.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['name'] ?? data['email'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['class'] != null && data['class'].toString().isNotEmpty)
                              Text('Sinf: ${data['class']}'),
                            if (data['group'] != null && data['group'].toString().isNotEmpty)
                              Text('Guruh: ${data['group']}'),
                            if (data['teacherEmail'] != null && data['teacherEmail'].toString().isNotEmpty)
                              Text('O\'qituvchi: ${data['teacherEmail']}'),
                            Text('Rol: ${data['role']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: validRoles.contains(data['role']) ? data['role'] : 'student',
                              items: const [
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'teacher', child: Text('O\'qituvchi')),
                                DropdownMenuItem(value: 'parent', child: Text('Ota-ona')),
                                DropdownMenuItem(value: 'student', child: Text('O\'quvchi')),
                              ],
                              onChanged: (v) {
                                if (v != null && v != data['role']) {
                                  _updateRole(user.id, v);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Tahrirlash',
                              onPressed: () => _editStudentDialog(user.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
