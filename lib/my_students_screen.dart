import 'shared/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Öğrencinin grubunu Firestore'dan dinamik olarak al

class MyStudentsScreen extends ConsumerWidget {
  const MyStudentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ders programı ekleme için controllerlar
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _detailsController = TextEditingController();
    final TextEditingController _groupController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('O\'quvchi Paneli'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === ADMIN DERS PROGRAMI EKLEME ALANI ===
            Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dars Jadvalini Qo\'shish (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Dars Mavzusi'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      decoration: const InputDecoration(labelText: 'Tavsif'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupController,
                      decoration: const InputDecoration(labelText: 'Guruh (masalan: A, B, 10A)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        return Scaffold(
                          appBar: AppBar(
                            title: const Text('Öğrenci Paneli'),
                          ),
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // === ADMIN DERS PROGRAMI EKLEME ALANI ===
                                // ...existing code...
                                // Duyurular
                                // ...existing code...
                                const SizedBox(height: 16),
                                // Ders Programı
                                Card(
                                  color: Colors.yellow.shade50,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_month, color: Colors.yellow.shade800, size: 36),
                                            const SizedBox(width: 12),
                                            const Text('Dars Jadvali', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Öğrencinin Firestore'daki grubuna göre ders programı göster
                                        StreamBuilder<DocumentSnapshot>(
                                          stream: FirebaseFirestore.instance.collection('students').doc(/* Giriş yapan öğrencinin ID'si */).snapshots(),
                                          builder: (context, studentSnapshot) {
                                            if (studentSnapshot.connectionState == ConnectionState.waiting) {
                                              return const Text('Yuklanmoqda...');
                                            }
                                            if (!studentSnapshot.hasData || !studentSnapshot.data!.exists) {
                                              return const Text('O\'quvchi ma\'lumoti topilmadi.');
                                            }
                                            final studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
                                            final group = studentData['group'] ?? '';
                                            return StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('schedules')
                                                  .where('group', isEqualTo: group)
                                                  .orderBy('date', descending: true)
                                                  .snapshots(),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                  return const Text('Yuklanmoqda...');
                                                }
                                                if (snapshot.hasError) {
                                                  return Text('Ders programı yüklenemedi: {snapshot.error}\nLütfen Firestore indexini oluşturun.');
                                                }
                                                final docs = snapshot.data?.docs ?? [];
                                                if (docs.isEmpty) {
                                                  return const Text('Hozircha dars jadvali yo\'q.');
                                                }
                                                return ListView.builder(
                                                  shrinkWrap: true,
                                                  physics: const NeverScrollableScrollPhysics(),
                                                  itemCount: docs.length,
                                                  itemBuilder: (context, index) {
                                                    final data = docs[index].data() as Map<String, dynamic>;
                                                    final title = data['title'] ?? '';
                                                    final details = data['details'] ?? '';
                                                    final group = data['group'] ?? '';
                                                    return ListTile(
                                                      title: Text(title),
                                                      subtitle: Text('Guruh: $group\n$details'),
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // ...existing code...
                              ],
                            ),
                          ),
                        );
                                          dateStr,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height = 16),
            // Ders Programı
            Card(
              color = Colors.yellow.shade50,
              shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child = Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: Colors.yellow.shade800, size: 36),
                        const SizedBox(width: 12),
                        const Text('Ders Programı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('schedules')
                          .where('group', isEqualTo: currentGroup)
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Yuklanmoqda...');
                        }
                        if (snapshot.hasError) {
                          return Text('Dars jadvali yuklanmadi: ${snapshot.error}\nIltimos, Firestore indeksini yarating.');
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Text('Hozircha dars jadvali yo\'q.');
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final title = data['title'] ?? '';
                            final content = data['content'] ?? data['details'] ?? data['description'] ?? '';
                            final timestamp = data['date'];
                            DateTime? date;
                            if (timestamp is Timestamp) {
                              date = timestamp.toDate();
                            } else if (timestamp is DateTime) {
                              date = timestamp;
                            } else if (timestamp is String) {
                              date = DateTime.tryParse(timestamp);
                            }
                            final dateStr = date != null ? "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}" : "";
                            return Card(
                              color: Colors.yellow.shade100,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text(content, style: const TextStyle(fontSize: 15)),
                                    if (dateStr.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ), // Column (Ders Programı)
              ), // Padding (Ders Programı)
            ), // Card (Ders Programı)
          ], // Ana Column children
        ), // Ana Column
      ), // SingleChildScrollView
    );
  }
}
