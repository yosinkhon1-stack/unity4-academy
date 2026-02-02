import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SmsSendScreen extends StatefulWidget {
  const SmsSendScreen({Key? key}) : super(key: key);

  @override
  State<SmsSendScreen> createState() => _SmsSendScreenState();
}

class _SmsSendScreenState extends State<SmsSendScreen> {
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedPhones = {};
  String _message = '';
  List<Map<String, String>> _students = [];
  List<Map<String, String>> _filteredStudents = [];
  bool _loadingStudents = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    final snap = await FirebaseFirestore.instance.collection('students').get();
    final students = snap.docs
        .map((doc) {
          final data = doc.data();
          final phone = data['phone']?.toString() ?? '';
          final name = data['name']?.toString() ?? '';
          if (phone.isNotEmpty) {
            return {'name': name, 'phone': phone};
          }
          return null;
        })
        .whereType<Map<String, String>>()
        .toList();
    
    // Sort students by name
    students.sort((a, b) => a['name']!.compareTo(b['name']!));

    setState(() {
      _students = students;
      _filteredStudents = students;
      _loadingStudents = false;
    });
  }

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _students.where((s) {
        return s['name']!.toLowerCase().contains(query) || s['phone']!.contains(query);
      }).toList();
    });
  }

  void _toggleSelectAll(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedPhones.addAll(_filteredStudents.map((s) => s['phone']!));
      } else {
        for (var s in _filteredStudents) {
          _selectedPhones.remove(s['phone']);
        }
      }
    });
  }

  void _sendSms() async {
    if (_selectedPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Iltimos, kamida bitta o\'quvchini tanlang.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Determine separator based on platform
    // Android usually prefers ';' for multiple recipients, iOS prefers ','
    String separator = ',';
    if (!kIsWeb && Platform.isAndroid) {
      separator = ';';
    }

    final String recipients = _selectedPhones.join(separator);
    final String encodedBody = Uri.encodeComponent(_message);
    
    // Multi-recipient SMS URI
    final Uri smsUri = Uri.parse('sms:$recipients?body=$encodedBody');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS ilovasini ochib bo\'lmadi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ommaviy SMS Yuborish'),
        centerTitle: true,
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form Section
                  ModernCard(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Xabaringiz',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.sms),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Xabar shart' : null,
                            onSaved: (v) => _message = v ?? '',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _sendSms,
                            icon: const Icon(Icons.send),
                            label: Text('${_selectedPhones.length} Kishiga SMS Yuborish'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search and Selection Header
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "O'quvchi qidirish...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          Checkbox(
                            value: _filteredStudents.isNotEmpty && 
                                   _filteredStudents.every((s) => _selectedPhones.contains(s['phone'])),
                            onChanged: _toggleSelectAll,
                          ),
                          const Text("Hammasi", style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Student List
                  Expanded(
                    child: ModernCard(
                      padding: EdgeInsets.zero,
                      child: _filteredStudents.isEmpty
                          ? const Center(child: Text("O'quvchi topilmadi."))
                          : ListView.separated(
                              itemCount: _filteredStudents.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final student = _filteredStudents[index];
                                final phone = student['phone']!;
                                final isSelected = _selectedPhones.contains(phone);

                                return CheckboxListTile(
                                  title: Text(student['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(phone),
                                  value: isSelected,
                                  secondary: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    child: const Icon(Icons.person, size: 20),
                                  ),
                                  onChanged: (bool? val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedPhones.add(phone);
                                      } else {
                                        _selectedPhones.remove(phone);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tanlangan: ${_selectedPhones.length} / ${_students.length}",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
