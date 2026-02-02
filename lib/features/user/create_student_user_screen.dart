import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/features/user/create_student_user_dialog.dart';

class CreateStudentUserScreen extends StatefulWidget {
  const CreateStudentUserScreen({Key? key}) : super(key: key);

  @override
  State<CreateStudentUserScreen> createState() => _CreateStudentUserScreenState();
}

class _CreateStudentUserScreenState extends State<CreateStudentUserScreen> {
  void _showCreateDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CreateStudentUserDialog(),
        ),
      ),
    );
    if (result == true) {
      setState(() {}); // Listeyi güncelle
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foydalanuvchi Yaratish'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add),
                label: const Text('Yangi Foydalanuvchi Yaratish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Hozircha foydalanuvchilar yo\'q.'));
                    }
                    final users = snapshot.data!.docs;
                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final user = users[i];
                        final data = user.data();
                        if (data is! Map<String, dynamic> || (!data.containsKey('username') && !data.containsKey('name'))) {
                          // Eksik veya hatalı belgeyi atla
                          return const ListTile(title: Text('Noto\'g\'ri foydalanuvchi ma\'lumoti'), subtitle: Text('Ma\'lumot yetishmayapti yoki buzilgan'));
                        }
                        final userData = data;
                        return ListTile(
                          title: Text(userData['name']?.toString() ?? ''),
                          subtitle: Text(userData['username']?.toString() ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final nameController = TextEditingController(text: userData['name']?.toString() ?? '');
                                  final usernameController = TextEditingController(text: userData['username']?.toString() ?? '');
                                  final passwordController = TextEditingController(text: userData['password']?.toString() ?? '');
                                  String? errorText;
                                  await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Foydalanuvchini Tahrirlash'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: usernameController,
                                              decoration: const InputDecoration(labelText: 'Foydalanuvchi Nomi'),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: passwordController,
                                              decoration: const InputDecoration(labelText: 'Parol'),
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: nameController,
                                              decoration: const InputDecoration(labelText: 'F.I.SH'),
                                            ),
                                            if (errorText != null) ...[
                                              const SizedBox(height: 8),
                                              Text(errorText ?? '', style: const TextStyle(color: Colors.red)),
                                            ]
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Bekor qilish'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final newUsername = usernameController.text.trim();
                                              final newPassword = passwordController.text.trim();
                                              final newName = nameController.text.trim();
                                              if ([newUsername, newPassword, newName].any((e) => e.isEmpty)) {
                                                errorText = 'Barcha maydonlar majburiy.';
                                                (context as Element).markNeedsBuild();
                                                return;
                                              }
                                              // Foydalanuvchi nomi o'zgargan bo'lsa, takrorlanmasligini tekshirish
                                              if (newUsername != (userData['username'] ?? '')) {
                                                final existing = await FirebaseFirestore.instance
                                                    .collection('students')
                                                    .where('username', isEqualTo: newUsername)
                                                    .limit(1)
                                                    .get();
                                                if (existing.docs.isNotEmpty) {
                                                  errorText = 'Bu foydalanuvchi nomi allaqachon olingan.';
                                                  (context as Element).markNeedsBuild();
                                                  return;
                                                }
                                              }
                                              await user.reference.update({
                                                'username': newUsername,
                                                'password': newPassword,
                                                'name': newName,
                                              });
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Saqlash'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await user.reference.delete();
                                },
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
      ),
    );
  }
}
