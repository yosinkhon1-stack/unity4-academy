import 'package:flutter/material.dart';
import 'admin_student_manager.dart';
import '../teachers/admin_teacher_manager.dart';
import '../payments/admin_payment_screen.dart'; // Ensure this is imported if needed, although it was used as dialog before

class AdminPanel extends StatelessWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue, size: 36),
                title: const Text('Ödeme Kartı Oluştur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: const Text('Yeni bir ödeme kartı oluşturmak için tıklayın.'),
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => const AdminPaymentDialog(),
                    barrierDismissible: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.group),
              label: const Text('Öğrenci Yönetimi'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminStudentManager()),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_pin_rounded),
              label: const Text("O'qituvchilar Yönetimi"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminTeacherManager()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Diğer admin yönetim butonları buraya eklenebilir
          ],
        ),
      ),
    );
  }
}
