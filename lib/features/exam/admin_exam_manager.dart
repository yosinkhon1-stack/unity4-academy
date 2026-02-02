import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:unity4_academy/generated/l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/shared/services/push_notification_service.dart';

class AdminExamManager extends StatefulWidget {
  const AdminExamManager({super.key});

  @override
  State<AdminExamManager> createState() => _AdminExamManagerState();
}

class _AdminExamManagerState extends State<AdminExamManager> {
  UploadTask? _uploadTask;
  String? _uploadedFileUrl;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _result = '';
  String? _selectedStudentId;
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loadingStudents = true);
    final snapshot = await FirebaseFirestore.instance.collection('students').orderBy('name').get();
    _students = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'class': data['class'] ?? '',
        'group': data['group'] ?? '',
        'teacherEmail': data['teacherEmail'] ?? '',
      };
    }).toList();
    setState(() => _loadingStudents = false);
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isUploading = true);
      final file = result.files.single;
      final fileName = file.name;
      final ref = FirebaseStorage.instance.ref().child('exams_files/$fileName');
      
      _uploadTask = ref.putData(file.bytes!);
      final snapshot = await _uploadTask!.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadedFileUrl = url;
        _isUploading = false;
      });
    }
  }

  Future<void> _addExam() async {
    if (_formKey.currentState!.validate() && _selectedStudentId != null) {
      _formKey.currentState!.save();
      final studentData = _students.firstWhere((s) => s['id'] == _selectedStudentId);
      await FirebaseFirestore.instance.collection('exams').add({
        'title': _title,
        'result': _result,
        'date': DateTime.now(),
        'type': 'sonuc',
        'studentId': _selectedStudentId,
        'teacherEmail': studentData['teacherEmail'],
        if (_uploadedFileUrl != null) 'fileUrl': _uploadedFileUrl,
      });

      // Send Specific Notification
      await PushNotificationService.sendNotificationRequest(
        targetUserEmail: _selectedStudentId!,
        title: "Imtihon Natijasi: $_title",
        body: "Sizning natijangiz: $_result",
      );

      setState(() {
        _title = '';
        _result = '';
        _selectedStudentId = null;
        _uploadedFileUrl = null;
      });
      if(mounted) FocusScope.of(context).unfocus();
    }
  }

  Future<void> _deleteExam(String id) async {
    await FirebaseFirestore.instance.collection('exams').doc(id).delete();
  }

  Future<void> _editExam(String id, String newTitle, String newResult) async {
    await FirebaseFirestore.instance.collection('exams').doc(id).update({
      'title': newTitle,
      'result': newResult,
      'type': 'sonuc',
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.examManagement), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // --- FORM SECTION ---
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Yangi Imtihon Natijasini Qo'shish", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    _loadingStudents
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<String>(
                            initialValue: _selectedStudentId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'O\'quvchini Tanlang', prefixIcon: Icon(Icons.person_search)),
                            items: _students
                                .map((student) => DropdownMenuItem<String>(
                                      value: student['id'],
                                      child: Text(
                                          '${student['name']} - ${student['class']}'),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedStudentId = val),
                            validator: (v) => v == null ? 'O\'quvchi tanlanishi shart' : null,
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Imtihon Mavzusi', prefixIcon: Icon(Icons.title)),
                      initialValue: _title,
                      onSaved: (v) => _title = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Imtihon mavzusi shart' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Natija (Ball/Baho)', prefixIcon: Icon(Icons.grade)),
                      initialValue: _result,
                      onSaved: (v) => _result = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Natija shart' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickAndUploadFile,
                            icon: _isUploading 
                                ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(strokeWidth: 2)) 
                                : const Icon(Icons.attach_file),
                            label: Text(_uploadedFileUrl != null ? "Fayl Qo'shildi" : 'Fayl Qo\'shish'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        if (_uploadedFileUrl != null && !_isUploading)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green.withOpacity(0.1),
                              child: const Icon(Icons.check, color: Colors.green, size: 20),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addExam,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Imtihon Qo\'shish'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "Imtihonlar Ro'yxati",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            
            // --- LIST SECTION ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exams').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Ro\'yxatdan o\'tgan imtihon yo\'q.', style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Resolving Student Name from local list
                    final studentId = data['studentId'] as String?;
                    final studentName = _students.firstWhere(
                        (s) => s['id'] == studentId, 
                        orElse: () => {'name': 'O\'quvchi Topilmadi'}
                    )['name'];

                    return ModernCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, color: Colors.purple, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName, 
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['title'] ?? 'Mavzusiz Imtihon',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Natija: ${data['result']}",
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'edit') {
                                final newTitle = await _showEditDialog(context, data['title'] ?? '', dialogTitle: 'Imtihon Mavzusini Tahrirlash');
                                final newResult = await _showEditDialog(context, data['result'] ?? '', dialogTitle: 'Natijani Tahrirlash');
                                if (newTitle != null && newResult != null) {
                                  _editExam(doc.id, newTitle, newResult);
                                }
                              } else if (val == 'delete') {
                                _deleteExam(doc.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Tahrirlash')])),
                              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
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

  Future<String?> _showEditDialog(BuildContext context, String initialValue, {String? dialogTitle}) async {
    final loc = S.of(context);
    final theme = Theme.of(context);
    final controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle ?? loc.userEditTitle, style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: loc.userEditHint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(loc.save)),
        ],
      ),
    );
  }
}
