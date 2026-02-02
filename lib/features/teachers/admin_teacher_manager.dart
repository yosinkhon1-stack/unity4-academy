import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';

class AdminTeacherManager extends StatefulWidget {
  const AdminTeacherManager({super.key});

  @override
  State<AdminTeacherManager> createState() => _AdminTeacherManagerState();
}

class _AdminTeacherManagerState extends State<AdminTeacherManager> {
  final _nameController = TextEditingController();
  final _proficiencyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _groupController = TextEditingController();
  
   String? _selectedGroup;
   List<String> _existingGroups = [];
   String? _editingTeacherId;

   @override
   void initState() {
     super.initState();
     _fetchExistingGroups();
   }

   Future<void> _fetchExistingGroups() async {
     final snapshot = await FirebaseFirestore.instance.collection('students').get();
     final groups = snapshot.docs
         .map((doc) => (doc.data()['group'] as String?)?.trim() ?? '')
         .where((g) => g.isNotEmpty)
         .toSet()
         .toList();
     groups.sort();
     if (mounted) {
       setState(() {
         _existingGroups = groups;
       });
     }
   }

  Future<void> _saveTeacher() async {
    final data = {
      'name': _nameController.text.trim(),
      'proficiency': _proficiencyController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'group': _groupController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_editingTeacherId != null) {
      await FirebaseFirestore.instance
          .collection('teachers_info')
          .doc(_editingTeacherId)
          .update(data);
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('teachers_info').add(data);
    }

    _clearForm();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editingTeacherId != null 
            ? 'O\'qituvchi muvaffaqiyatli yangilandi.' 
            : 'O\'qituvchi muvaffaqiyatli saqlandi.'), 
          backgroundColor: Colors.green
        ),
      );
      setState(() {
        _editingTeacherId = null;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _proficiencyController.clear();
    _phoneController.clear();
    _emailController.clear();
    _groupController.clear();
    setState(() {
      _editingTeacherId = null;
    });
  }

  void _editTeacher(String id, Map<String, dynamic> data) {
    setState(() {
      _editingTeacherId = id;
      _nameController.text = data['name'] ?? '';
      _proficiencyController.text = data['proficiency'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _groupController.text = data['group'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('O\'qituvchilarni Boshqarish'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(_editingTeacherId != null ? Icons.edit : Icons.person_add, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(_editingTeacherId != null ? "O'qituvchini Tahrirlash" : "Yangi O'qituvchi", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (_editingTeacherId != null) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () => _clearForm(),
                          child: const Text("Bekor qilish"),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'F.I.SH', prefixIcon: Icon(Icons.badge))),
                  const SizedBox(height: 12),
                  TextField(controller: _proficiencyController, decoration: const InputDecoration(labelText: 'Darajasi (IELTS/CEFR)', prefixIcon: Icon(Icons.workspace_premium))),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone))),
                  const SizedBox(height: 12),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                  const SizedBox(height: 12),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return _existingGroups.where((String option) {
                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _selectedGroup = selection;
                        _groupController.text = selection;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Guruh (Biriktirilgan) - Tanlang yoki yozing',
                          prefixIcon: Icon(Icons.group),
                        ),
                        onChanged: (val) {
                          _groupController.text = val;
                          _selectedGroup = val;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ism va email majburiy!')),
                        );
                        return;
                      }
                      _saveTeacher();
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(_editingTeacherId != null ? 'Yangilash' : 'Saqlash'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text("Mavjud O'qituvchilar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('teachers_info').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("O'qituvchilar mavjud emas."));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ModernCard(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text("${data['proficiency']}\nGuruh: ${data['group']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTeacher(docs[index].id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => FirebaseFirestore.instance.collection('teachers_info').doc(docs[index].id).delete(),
                            ),
                          ],
                        ),
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
}
