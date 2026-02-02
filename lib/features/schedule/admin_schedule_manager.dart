import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unity4_academy/generated/l10n.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';

import 'sms_send_screen.dart';

class AdminScheduleManager extends StatefulWidget {
  const AdminScheduleManager({super.key});

  @override
  State<AdminScheduleManager> createState() => _AdminScheduleManagerState();
}

class _AdminScheduleManagerState extends State<AdminScheduleManager> {
  UploadTask? _uploadTask;
  String? _uploadedFileUrl;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _details = '';
  String _group = '';

  Future<void> _launchFileUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faylni ochib bo\'lmadi.')),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isUploading = true);
      
      final file = result.files.single;
      final fileName = file.name;
      final ref = FirebaseStorage.instance.ref().child('schedules_files/$fileName');
      
      _uploadTask = ref.putData(file.bytes!);
      final snapshot = await _uploadTask!.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      
      setState(() {
        _uploadedFileUrl = url;
        _isUploading = false;
      });
    }
  }

  Future<void> _addSchedule() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await FirebaseFirestore.instance.collection('schedules').add({
        'title': _title,
        'details': _details,
        'group': _group,
        'date': DateTime.now(),
        if (_uploadedFileUrl != null) 'fileUrl': _uploadedFileUrl,
        'type': 'ders_programi',
      });
      setState(() {
        _title = '';
        _details = '';
        _group = '';
        _uploadedFileUrl = null;
      });
      if(mounted) FocusScope.of(context).unfocus();
    }
  }

  Future<void> _deleteSchedule(String id) async {
    await FirebaseFirestore.instance.collection('schedules').doc(id).delete();
  }

  Future<void> _editSchedule(String id, String newTitle, String newDetails) async {
    await FirebaseFirestore.instance.collection('schedules').doc(id).update({
      'title': newTitle,
      'details': newDetails,
      'type': 'ders_programi',
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.scheduleManagement), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            
            // --- FORM SECTION ---
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Dars Jadvalini Qo'shish", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                       decoration: const InputDecoration(labelText: 'Dars Mavzusi', prefixIcon: Icon(Icons.class_)),
                      initialValue: _title,
                      onSaved: (v) => _title = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Dars mavzusi shart' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tavsif', prefixIcon: Icon(Icons.description)),
                      initialValue: _details,
                      onSaved: (v) => _details = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Tavsif shart' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                       decoration: const InputDecoration(labelText: 'Guruh (masalan: A, B, 10A)', prefixIcon: Icon(Icons.group)),
                      initialValue: _group,
                      onSaved: (v) => _group = v ?? '',
                      validator: (v) => v == null || v.isEmpty ? 'Guruh shart' : null,
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
                      onPressed: _addSchedule,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Jadvalni Qo\'shish'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "Dars Jadvali Ro'yxati",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            
            // --- LIST SECTION ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('schedules').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Ro\'yxatdan o\'tgan dars jadvali yo\'q.', style: TextStyle(color: Colors.grey)));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return ModernCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.today, color: Colors.blueGrey, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['title'] ?? '',
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            data['group'] ?? '',
                                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(data['details'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) async {
                                  if (val == 'edit') {
                                    final newTitle = await _showEditDialog(context, data['title'] ?? '', dialogTitle: 'Dars Mavzusini Tahrirlash');
                                    final newDetails = await _showEditDialog(context, data['details'] ?? '', dialogTitle: 'Tavsifni Tahrirlash');
                                    if (newTitle != null && newDetails != null) {
                                      _editSchedule(doc.id, newTitle, newDetails);
                                    }
                                  } else if (val == 'delete') {
                                    _deleteSchedule(doc.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Tahrirlash')])),
                                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('O\'chirish', style: TextStyle(color: Colors.red))])),
                                ],
                              ),
                            ],
                          ),
                          if(data['fileUrl'] != null)
                             Padding(
                               padding: const EdgeInsets.only(top: 12.0),
                               child: InkWell(
                                onTap: () => _launchFileUrl(data['fileUrl']),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       const Icon(Icons.attach_file, size: 18, color: Colors.blue),
                                       const SizedBox(width: 8),
                                       Text("Faylni Ko'rish", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                                     ],
                                   ),
                                ),
                              ),
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
    final controller = TextEditingController(text: initialValue);
    final theme = Theme.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle ?? 'Tahrirlash', style: theme.textTheme.titleLarge),
        content: TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor qilish')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Saqlash')),
        ],
      ),
    );
  }
}
