import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/generated/l10n.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';

class AdminStudentManager extends StatefulWidget {
  const AdminStudentManager({super.key});

  @override
  State<AdminStudentManager> createState() => _AdminStudentManagerState();
}


class _AdminStudentManagerState extends State<AdminStudentManager> {
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _groupController = TextEditingController();
  final _teacherController = TextEditingController();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _filterClass;
  String? _filterGroup;
  String? _filterTeacher;

  Future<void> _editStudent(String id, Map<String, dynamic> newData) async {
    await FirebaseFirestore.instance.collection('students').doc(id).update({
      ...newData,
      'type': 'ogrenci',
    });
  }

  Future<void> _addStudent() async {
    if (_nameController.text.isEmpty || _loginController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    // Check duplicates
    final existing = await FirebaseFirestore.instance
        .collection('students')
        .where('username', isEqualTo: _loginController.text)
        .get();
    if (existing.docs.isNotEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ushbu login (foydalanuvchi nomi) allaqachon mavjud!'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    
    await FirebaseFirestore.instance.collection('students').add({
      'name': _nameController.text,
      'class': _classController.text,
      'group': _groupController.text,
      'teacherEmail': _teacherController.text,
      'teacher': _teacherController.text,
      'username': _loginController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'ogrenci',
    });
    
    _nameController.clear();
    _classController.clear();
    _groupController.clear();
    _teacherController.clear();
    _loginController.clear();
    _passwordController.clear();
    _phoneController.clear();
    setState(() {});
    
    if(mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O\'quvchi muvaffaqiyatli qo\'shildi.'), backgroundColor: Colors.green),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.userManagement), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- ADD STUDENT FORM ---
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_add, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                       Text("Yangi O'quvchi Qo'shish", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'O\'quvchi Ismi', prefixIcon: Icon(Icons.badge)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefon Raqami', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _classController,
                          decoration: const InputDecoration(labelText: 'Sinf'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _groupController,
                          decoration: const InputDecoration(labelText: 'Guruh'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _teacherController,
                    decoration: const InputDecoration(labelText: 'O\'qituvchi E-pochtasi', prefixIcon: Icon(Icons.email)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _loginController,
                          decoration: const InputDecoration(labelText: 'Login (Foydalanuvchi nomi)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Parol'),
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _addStudent,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Qo\'shish'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // --- FILTERS ---
            ModernCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filtrlash", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Sinf', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                          onChanged: (v) => setState(() => _filterClass = v.isEmpty ? null : v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Guruh', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                          onChanged: (v) => setState(() => _filterGroup = v.isEmpty ? null : v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'O\'qituvchi', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                          onChanged: (v) => setState(() => _filterTeacher = v.isEmpty ? null : v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            // --- LIST ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final students = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final classMatch = _filterClass == null || (data['class'] ?? '').toString().toLowerCase().contains(_filterClass!.toLowerCase());
                  final groupMatch = _filterGroup == null || (data['group'] ?? '').toString().toLowerCase().contains(_filterGroup!.toLowerCase());
                  final teacherMatch = _filterTeacher == null || (data['teacher'] ?? '').toString().toLowerCase().contains(_filterTeacher!.toLowerCase());
                  return classMatch && groupMatch && teacherMatch;
                }).toList();
                
                if (students.isEmpty) {
                   return const Center(child: Text('Ro\'yxatdan o\'tgan o\'quvchi topilmadi.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final data = student.data() as Map<String, dynamic>;
                    
                    return ModernCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, color: theme.colorScheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'] ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if ((data['class'] ?? '').toString().isNotEmpty)
                                          _buildTag(context, 'Sinf: ${data['class']}'),
                                        if ((data['group'] ?? '').toString().isNotEmpty)
                                          _buildTag(context, 'Guruh: ${data['group']}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    _showEditDialog(context, student, data);
                                  } else if (val == 'delete') {
                                    await FirebaseFirestore.instance.collection('students').doc(student.id).delete();
                                    setState(() {});
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Tahrirlash')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.school, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text('O\'qituvchi: ${data['teacher'] ?? '-'}', style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Telefon: ${data['phone'] ?? '-'}', style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.login, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Login: ${data['username'] ?? '-'}', style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                               Expanded(child: Text('Parol: ${data['password'] ?? '******'}', style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _showEditDialog(BuildContext context, DocumentSnapshot student, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final classController = TextEditingController(text: data['class'] ?? '');
    final groupController = TextEditingController(text: data['group'] ?? '');
    final teacherController = TextEditingController(text: data['teacherEmail'] ?? data['teacher'] ?? '');
    final loginController = TextEditingController(text: data['username'] ?? '');
    final passwordController = TextEditingController(text: data['password'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');

    final theme = Theme.of(context);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'O\'quvchi Ma\'lumotlarini Tahrirlash',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                _buildEditField(nameController, 'O\'quvchi Ismi', Icons.person),
                const SizedBox(height: 16),
                _buildEditField(phoneController, 'Telefon Raqami', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildEditField(classController, 'Sinf', Icons.school_outlined)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildEditField(groupController, 'Guruh', Icons.group_outlined)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEditField(teacherController, 'O\'qituvchi Email', Icons.email_outlined),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kirish Ma\'lumotlari', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 12),
                      _buildEditField(loginController, 'Login (Foydalanuvchi nomi)', Icons.login),
                      const SizedBox(height: 12),
                      _buildEditField(passwordController, 'Parol', Icons.lock_outline, obscure: true),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Bekor qilish', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop({
                          'name': nameController.text.trim(),
                          'class': classController.text.trim(),
                          'group': groupController.text.trim(),
                          'teacher': teacherController.text.trim(),
                          'teacherEmail': teacherController.text.trim(),
                          'username': loginController.text.trim(),
                          'password': passwordController.text.trim(),
                          'phone': phoneController.text.trim(),
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Saqlash'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      await _editStudent(student.id, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ma\'lumotlar yangilandi'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, 
      {bool obscure = false, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
