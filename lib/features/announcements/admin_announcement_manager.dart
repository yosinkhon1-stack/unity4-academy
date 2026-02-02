import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/generated/l10n.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/shared/services/push_notification_service.dart';

class AdminAnnouncementManager extends StatefulWidget {
  const AdminAnnouncementManager({Key? key}) : super(key: key);

  @override
  _AdminAnnouncementManagerState createState() =>
      _AdminAnnouncementManagerState();
}

class _AdminAnnouncementManagerState extends State<AdminAnnouncementManager> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _content = '';

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.announcementManagement), centerTitle: true),
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
                    Text(
                      loc.addAnnouncement,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.title,
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      initialValue: _title,
                      onSaved: (v) => setState(() => _title = v ?? ''),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.enterTitle : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: loc.message,
                        prefixIcon: const Icon(Icons.message),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      initialValue: _content,
                      onSaved: (v) => setState(() => _content = v ?? ''),
                      validator: (v) =>
                          v == null || v.isEmpty ? loc.enterMessage : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addAnnouncement,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        loc.addAnnouncement,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                loc.announcements,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            
            // --- LIST SECTION ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text(loc.noAnnouncements, style: const TextStyle(color: Colors.grey)));
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.campaign, color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  data['title'] ?? '',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                     final newTitle = await _showEditDialog(
                                        context, data['title'] ?? '',
                                        dialogTitle: loc.editTitle);
                                     final newContent = await _showEditDialog(
                                        context, data['content'] ?? '',
                                        dialogTitle: loc.editMessage);
                                    if (newTitle != null && newContent != null) {
                                      _editAnnouncement(doc.id, newTitle, newContent);
                                    }
                                  } else if (value == 'delete') {
                                    _deleteAnnouncement(doc.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [const Icon(Icons.edit, size: 20), const SizedBox(width: 8), Text(loc.edit)]),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [const Icon(Icons.delete, color: Colors.red, size: 20), const SizedBox(width: 8), Text(loc.delete, style: const TextStyle(color: Colors.red))]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(data['content'] ?? '', style: theme.textTheme.bodyMedium),
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

  Future<void> _addAnnouncement() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _title,
        'content': _content,
        'date': DateTime.now(),
        'type': 'duyuru',
      });

      // Send Universal Notification
      await PushNotificationService.sendNotificationRequest(
        targetUserEmail: 'all',
        title: "Yangi E'lon: $_title",
        body: _content,
        toAll: true,
      );

      setState(() {
        _title = '';
        _content = '';
      });
      if(mounted) FocusScope.of(context).unfocus();
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(id)
        .delete();
  }

  Future<void> _editAnnouncement(
      String id, String newTitle, String newContent) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(id)
        .update({
      'title': newTitle,
      'content': newContent,
      'type': 'duyuru',
    });
  }

  Future<String?> _showEditDialog(BuildContext context, String initialValue,
      {String? dialogTitle}) async {
    final controller = TextEditingController(text: initialValue);
    final loc = S.of(context);
    final theme = Theme.of(context);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle ?? loc.userEditTitle, style: theme.textTheme.titleLarge),
        content: TextField(
          controller: controller,
          maxLines: null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(loc.save)),
        ],
      ),
    );
  }
}
