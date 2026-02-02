import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unity4_academy/main.dart'; // for teacherEmailProvider

class TeacherVideoManager extends ConsumerStatefulWidget {
  const TeacherVideoManager({super.key});

  @override
  ConsumerState<TeacherVideoManager> createState() => _TeacherVideoManagerState();
}

class _TeacherVideoManagerState extends ConsumerState<TeacherVideoManager> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedStatus = 'Tavsiya';
  final List<String> _statuses = ['Majburiy', 'Tavsiya', 'Yangi', 'Muhim', 'Nazorat'];
  
  List<String> _availableGroups = [];
  final List<String> _selectedGroups = [];
  bool _isAllGroups = false;
  bool _isForGuests = false;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final teacherEmail = ref.read(teacherEmailProvider);
    if (teacherEmail == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('teacherEmail', isEqualTo: teacherEmail)
        .get();
        
    final groups = snapshot.docs
        .map((doc) => (doc.data()['group'] as String? ?? '').trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    groups.sort();
    setState(() {
      _availableGroups = groups;
    });
  }

  String? _getYoutubeId(String url) {
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('v=')) {
      return url.split('v=').last.split('&').first;
    } else if (url.contains('embed/')) {
      return url.split('embed/').last.split('?').first;
    }
    return url; // Assume it might be just ID if no URL pattern matches
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAllGroups && _selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos, guruhni tanlang!")),
      );
      return;
    }

    try {
      final teacherEmail = ref.read(teacherEmailProvider);
      final videoId = _getYoutubeId(_urlController.text.trim());

      await FirebaseFirestore.instance.collection('video_lessons').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'url': _urlController.text.trim(),
        'videoId': videoId,
        'status': _selectedStatus,
        'targetGroups': _isAllGroups 
            ? ['all'] 
            : _selectedGroups.map((g) => g.trim()).toList(),
        'isForGuests': _isForGuests,
        'teacherEmail': teacherEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video darslik muvaffaqiyatli qo'shildi!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Firebase Save Error: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Xatolik"),
            content: Text("Videoni saqlashda xato yuz berdi: $e\n\nIltimos, internet aloqasini va ruxsatlarni tekshiring."),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _urlController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedGroups.clear();
      _selectedGroups.clear();
      _isAllGroups = false;
      _isForGuests = false;
      _selectedStatus = 'Tavsiya';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final teacherEmail = ref.watch(teacherEmailProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Video Darslar Boshqaruvi"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ModernCard(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.video_call_rounded, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text("Yangi Video Qo'shish", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Video Sarlavhasi', prefixIcon: Icon(Icons.title)),
                      validator: (v) => v!.isEmpty ? 'Sarlavha kiriting' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(labelText: 'YouTube Link', prefixIcon: Icon(Icons.link), hintText: 'https://youtube.com/watch?v=...'),
                      validator: (v) => v!.isEmpty ? 'Link kiriting' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Tavsif / Izoh', prefixIcon: Icon(Icons.description)),
                    ),
                    const SizedBox(height: 20),
                    
                    const Text("Video Holati (Status)", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _statuses.map((s) => ChoiceChip(
                        label: Text(s),
                        selected: _selectedStatus == s,
                        onSelected: (val) => setState(() => _selectedStatus = s),
                      )).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    const Text("Kimlar ko'ra oladi?", style: TextStyle(fontWeight: FontWeight.w600)),
                    CheckboxListTile(
                      title: const Text("Barcha o'quvchilar"),
                      value: _isAllGroups,
                      onChanged: (v) => setState(() => _isAllGroups = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    if (!_isAllGroups)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Wrap(
                          spacing: 8,
                          children: _availableGroups.map((group) => FilterChip(
                            label: Text(group),
                            selected: _selectedGroups.contains(group),
                            onSelected: (val) {
                              setState(() {
                                if (val) _selectedGroups.add(group);
                                else _selectedGroups.remove(group);
                              });
                            },
                          )).toList(),
                        ),
                      ),
                     
                    const Divider(height: 24),
                    CheckboxListTile(
                      title: const Text("A'zo bo'lmaganlar (Mehmonlar) ga ko'rsatish"),
                      subtitle: const Text("Ushbu video 'A'zo emasman' bo'limida demo dars sifatida chiqadi", style: TextStyle(fontSize: 11)),
                      value: _isForGuests,
                      onChanged: (v) => setState(() => _isForGuests = v!),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.orange,
                    ),
                    
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveVideo,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text("SAQLASH VA YUBORISH"),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text("Mening Yuklagan Videolarim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('video_lessons')
                  .where('teacherEmail', isEqualTo: teacherEmail)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Ma'lumot yuklashda xato: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
                  ));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Hozircha video yuklamagansiz", style: TextStyle(color: Colors.grey)),
                ));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final targets = data['targetGroups'] as List<dynamic>? ?? [];
                    final targetStr = targets.contains('all') ? 'Barchaga' : targets.join(', ');

                    return ModernCard(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.play_circle_fill)),
                        title: Text(data['title'] ?? ''),
                        subtitle: Text("Guruh: $targetStr\nMehmonlar: ${data['isForGuests'] == true ? 'Ha' : 'Yo\'q'} | Status: ${data['status']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _confirmDelete(docs[index].id),
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

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("O'chirish"),
        content: const Text("Ushbu video darslikni o'chirib tashlamoqchimisiz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('video_lessons').doc(docId).delete();
              if (mounted) Navigator.pop(ctx);
            }, 
            child: const Text("O'chirish", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}
