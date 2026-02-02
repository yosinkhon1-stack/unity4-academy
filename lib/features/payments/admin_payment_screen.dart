import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';

class AdminPaymentScreen extends StatefulWidget {
  final String? studentId;
  const AdminPaymentScreen({Key? key, this.studentId}) : super(key: key);

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedStudentId;
  bool _loading = false;
  List<Map<String, dynamic>> _students = [];
  String? _editingPaymentId;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    if (widget.studentId != null) {
      _selectedStudentId = widget.studentId;
    }
    _cleanupDuplicates();
  }

  Future<void> _cleanupDuplicates() async {
    // Bazadagi barcha to'lovlarni olish
    final snapshot = await FirebaseFirestore.instance.collection('payments').get();
    final Map<String, List<DocumentSnapshot>> studentMap = {};
    
    for (var doc in snapshot.docs) {
      final sid = (doc.data()['studentId'] as String?)?.trim();
      if (sid == null || sid.isEmpty) continue;
      studentMap.putIfAbsent(sid, () => []).add(doc);
    }

    // Har bir o'quvchi uchun bittadan ko'p karta bo'lsa, eng yangisini (dueDate eng kech bo'lganini) qoldirib, qolganlarini o'chirish
    for (var sid in studentMap.keys) {
      final docs = studentMap[sid]!;
      if (docs.length > 1) {
        docs.sort((a, b) {
          final da = (a.data() as Map<String, dynamic>)['dueDate'] as Timestamp?;
          final db = (b.data() as Map<String, dynamic>)['dueDate'] as Timestamp?;
          return (db?.seconds ?? 0).compareTo(da?.seconds ?? 0);
        });
        
        // Birinchisini (eng yangi muddatlisini) saqlab, qolganlarini bazadan o'chirish
        for (int i = 1; i < docs.length; i++) {
          await FirebaseFirestore.instance.collection('payments').doc(docs[i].id).delete();
        }
      }
    }
  }

  Future<void> _fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('students').orderBy('name').get();
    setState(() {
      _students = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();
    });
  }

  Future<void> _savePayment() async {
    if (_selectedStudentId == null || _amountController.text.isEmpty) return;
    setState(() => _loading = true);
    
    final amount = int.tryParse(_amountController.text) ?? 0;
    final paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
    
    final data = {
      'studentId': _selectedStudentId,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': _dueDate,
      'createdAt': DateTime.now(),
    };

    if (_editingPaymentId == null) {
      // Bitta karta bo'lishi uchun oldin bu o'quvchining kartasi bor-yo'qligini tekshiramiz
      final existing = await FirebaseFirestore.instance
          .collection('payments')
          .where('studentId', isEqualTo: _selectedStudentId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Bo'lsa uni yangilaymiz (Yangi karta yaratmaymiz)
        await FirebaseFirestore.instance.collection('payments').doc(existing.docs.first.id).update(data);
      } else {
        // Yo'q bo'lsa yangi yaratamiz
        await FirebaseFirestore.instance.collection('payments').add(data);
      }
    } else {
      await FirebaseFirestore.instance.collection('payments').doc(_editingPaymentId).update(data);
    }

    setState(() {
      _editingPaymentId = null;
      _amountController.clear();
      _paidAmountController.clear();
      _dueDate = null;
      _selectedStudentId = null;
      _loading = false;
    });
  }

  void _editPayment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingPaymentId = doc.id;
      _selectedStudentId = data['studentId'];
      _amountController.text = data['amount']?.toString() ?? '';
      _paidAmountController.text = (data['paidAmount'] ?? data['paid'] ?? '').toString();
      _dueDate = data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null;
    });
  }

  Future<void> _deletePayment(String id) async {
    // 1. Asosiy to'lov kartasini o'chirish
    await FirebaseFirestore.instance.collection('payments').doc(id).delete();

    // 2. Bu kartaga tegishli o'tmish (arxiv) yozuvlarini ham to'liq tozalash (Iz qolmasin)
    final historyDocs = await FirebaseFirestore.instance
        .collection('payments_history')
        .where('originalId', isEqualTo: id)
        .get();
    
    for (var doc in historyDocs.docs) {
      await FirebaseFirestore.instance.collection('payments_history').doc(doc.id).delete();
    }

    setState(() {
      if (_editingPaymentId == id) {
        _editingPaymentId = null;
        _amountController.clear();
        _paidAmountController.clear();
        _dueDate = null;
        _selectedStudentId = null;
      }
    });
  }

  Future<void> _markAsPaid(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0);
    final studentId = data['studentId'];

    // 1. Arxivlash (O'tmishga yozish)
    await FirebaseFirestore.instance.collection('payments_history').add({
      ...data,
      'status': 'Paid',
      'paidAt': DateTime.now(),
      'originalId': doc.id,
    });

    // 2. Mavjud kartani "To'langan" sifatida yangilash (Sanani o'zgartirmaymiz, foydalanuvchi 1 oy yashil ko'rishni xohlaydi)
    await FirebaseFirestore.instance.collection('payments').doc(doc.id).update({
      'paidAmount': amount,
    });
  }

  Future<void> _cyclePayment(String docId, Map<String, dynamic> data) async {
    final dueDateTs = data['dueDate'] as Timestamp?;
    if (dueDateTs == null) return;
    
    final currentDueDate = dueDateTs.toDate();
    // Sanani ROSMANA 1 OY oldinga surish
    final nextDueDate = DateTime(currentDueDate.year, currentDueDate.month + 1, currentDueDate.day);
    
    await FirebaseFirestore.instance.collection('payments').doc(docId).update({
      'dueDate': nextDueDate,
      'paidAmount': 0, // Yangi oy boshlangani uchun to'langan miqdorni nolga tenglashtirish
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lov Kartalarini Boshqarish'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- FORM SECTION ---
              ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _editingPaymentId == null ? 'Yangi To\'lov Yaratish' : 'To\'lovni Tahrirlash',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(
                        labelText: 'O\'quvchini Tanlang',
                        prefixIcon: Icon(Icons.person_search),
                      ),
                      items: _students
                          .map((student) => DropdownMenuItem<String>(
                                value: student['id'],
                                child: Text(student['name']),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedStudentId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                             decoration: const InputDecoration(
                                labelText: "Miqdor",
                                suffixText: "so'm",
                              ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _paidAmountController,
                            keyboardType: TextInputType.number,
                             decoration: const InputDecoration(
                                labelText: "To'langan",
                                suffixText: "so'm",
                              ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      child: InputDecorator(
                         decoration: const InputDecoration(
                          labelText: 'Oxirgi To\'lov Sanasi',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                         child: Text(
                          _dueDate == null
                              ? 'Sana Tanlang'
                              : "${_dueDate!.day.toString().padLeft(2, '0')}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.year}",
                          style: _dueDate == null ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_editingPaymentId != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _editingPaymentId = null;
                              _amountController.clear();
                              _paidAmountController.clear();
                              _dueDate = null;
                              _selectedStudentId = null;
                            }),
                             child: const Text('Bekor qilish'),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _loading ? null : _savePayment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                               : Text(_editingPaymentId == null ? 'Saqlash' : 'Yangilash'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
               Text(
                "Oxirgi Amallar",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // --- LIST SECTION ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final allDocs = snapshot.data?.docs ?? [];
                  
                  // 1. Har bir o'quvchi uchun faqat bitta karta ko'rsatish (Eng yangisi)
                  final Map<String, DocumentSnapshot> uniquePayments = {};
                  for (var doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final studentId = (data['studentId'] as String?)?.trim();
                    if (studentId == null || studentId.isEmpty) continue;
                    
                    if (!uniquePayments.containsKey(studentId)) {
                      uniquePayments[studentId] = doc;
                    } else {
                      final existingTs = (uniquePayments[studentId]!.data() as Map<String, dynamic>)['dueDate'] as Timestamp?;
                      final currentTs = data['dueDate'] as Timestamp?;
                      if (currentTs != null && (existingTs == null || currentTs.seconds > existingTs.seconds)) {
                        uniquePayments[studentId] = doc;
                      }
                    }
                  }

                  final docs = uniquePayments.values.toList();
                  
                  // 2. Avtomatik O'tish: Bir oy o'tgan bo'lsa kartani nolga tushirib keyingi oyga o'tkazish
                  Future.delayed(Duration.zero, () {
                    if (!mounted) return;
                    final now = DateTime.now();
                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = (data['amount'] ?? 0);
                      final paidAmount = (data['paidAmount'] ?? 0);
                      final isPaid = paidAmount >= amount;
                      final dueDateTs = data['dueDate'] as Timestamp?;
                      
                      if (isPaid && dueDateTs != null) {
                        final dueDate = dueDateTs.toDate();
                        // KEYINGI OYNING SANASI: Mavjud muddatdan roppa-rosa 1 oy keyin
                        final nextCycleDate = DateTime(dueDate.year, dueDate.month + 1, dueDate.day);
                        
                        // QOIDA: Agar BUGUN, keyingi oyning to'lov sanasiga YETGAN bo'lsa (muddat tugagan bo'lsa) o'tkazish.
                        if (now.isAfter(nextCycleDate) || (now.year == nextCycleDate.year && now.month == nextCycleDate.month && now.day >= nextCycleDate.day)) {
                          _cyclePayment(doc.id, data);
                        }
                      }
                    }
                  });

                   if (docs.isEmpty) {
                    return const Center(child: Text('Hali to\'lov kartasi yo\'q.'));
                  }
                  
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final amount = (data['amount'] ?? 0);
                      final paid = (data['paidAmount'] ?? data['paid'] ?? 0);
                      final isPaid = paid >= amount;
                      final dueDate = data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null;
                      final isOverdue = !isPaid && dueDate != null && DateTime.now().isAfter(dueDate);
                      
                      final studentName = _students.firstWhere(
                          (s) => s['id'] == data['studentId'],
                          orElse: () => {'name': 'Noma\'lum'})['name'];

                      return ModernCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isPaid 
                                  ? Colors.green.withOpacity(0.1) 
                                  : (isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPaid ? Icons.check : (isOverdue ? Icons.warning_amber_rounded : Icons.access_time),
                                color: isPaid ? Colors.green : (isOverdue ? Colors.red : Colors.orange),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(studentName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(
                                    "$paid / $amount so'm",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isOverdue ? Colors.red : Colors.grey.shade700,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  if(dueDate != null)
                                    Text(
                                      "${dueDate.day.toString().padLeft(2, '0')}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.year}", 
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: isOverdue ? Colors.red.shade300 : Colors.grey
                                      )
                                    ),
                                ],
                              ),
                            ),
                             Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isPaid)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                     onPressed: () => _markAsPaid(docs[i]),
                                    tooltip: 'To\'langan deb belgilash',
                                  ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 20, color: theme.colorScheme.primary),
                                   onPressed: () => _editPayment(docs[i]),
                                  tooltip: 'Tahrirlash',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                                   onPressed: () => _deletePayment(docs[i].id),
                                  tooltip: 'O\'chirish',
                                ),
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
      ),
    );
  }
}
