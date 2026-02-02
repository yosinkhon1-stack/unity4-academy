import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity4_academy/shared/widgets/modern_card.dart';
import 'package:unity4_academy/shared/services/telegram_service.dart';
import 'package:unity4_academy/features/videos/video_player_screen.dart';

class PromoScreen extends StatelessWidget {
  const PromoScreen({Key? key}) : super(key: key);

  void _showApplicationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final courseController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.edit_note_rounded, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            const Text(
              "Kursga ariza topshirish",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "F.I.SH",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Telefon raqamingiz",
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: "+998 90 123 45 67",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: "Qaysi kurs uchun?",
                  prefixIcon: Icon(Icons.school_outlined),
                  hintText: "Masalan: Ingliz tili, Matematika...",
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Qo'shimcha izoh",
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Iltimos, ism va telefon raqamingizni kiriting")),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('course_applications').add({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'course': courseController.text.trim(),
                  'note': noteController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'yangi',
                });

                // --- Telegram Notification ---
                try {
                  await TelegramService.sendApplicationNotification(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    course: courseController.text.trim(),
                    note: noteController.text.trim(),
                  );
                } catch (telegramErr) {
                  print("Telegram notify failed: $telegramErr");
                }

                if (context.mounted) {
                  Navigator.pop(ctx); // Close application dialog
                  
                  // Show Success Dialog
                  showDialog(
                    context: context,
                    builder: (successCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 80),
                          const SizedBox(height: 20),
                          const Text(
                            "Muvaffaqiyatli!",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Arizangiz qabul qilindi. Tez orada operatorlarimiz siz bilan bog'lanishadi.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(successCtx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text("Tushunarli"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hato yuz berdi: $e")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Yuborish"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BACK BUTTON ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 20),

                // --- HERO SECTION ---
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (ctx, err, stack) => Icon(Icons.school, size: 80, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "UNITY4 ACADEMY",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Kelajakni Biz Bilan Quring!",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Siz hali bizning safimizda emasmisiz? \nUnity4 Academy bilan zamonaviy ta'lim olamiga qadam qo'ying.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 48),

                const SizedBox(height: 24),

                // --- VIDEO LESSONS SECTION ---
                _buildSectionLabel(context, "Demo Video Darslar"),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('video_lessons')
                      .where('isForGuests', isEqualTo: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Hozircha demo videolar mavjud emas", style: TextStyle(color: Colors.grey)));
                    }
                    final videos = snapshot.data!.docs;
                    return SizedBox(
                      height: 230, // Increased height
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        itemCount: videos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final v = videos[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    videoId: v['videoId'] ?? '',
                                    title: v['title'] ?? '',
                                    description: v['description'] ?? '',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 240, // Wider cards
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08), 
                                    blurRadius: 15,
                                    offset: const Offset(0, 5)
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: Image.network(
                                          "https://img.youtube.com/vi/${v['videoId']}/0.jpg",
                                          height: 130, // Taller image
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Center(
                                          child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 40),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['title'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: const [
                                            Icon(Icons.bolt, color: Colors.orange, size: 14),
                                            SizedBox(width: 4),
                                            Text("BEPUL DARSLIK", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // --- WHY CHOOSE US ---
                _buildSectionLabel(context, "Nega Bizni Tanlashadi?"),
                const SizedBox(height: 16),

                _buildFeatureItem(
                  context,
                  icon: Icons.workspace_premium, 
                  title: "Malakali Ustozlar",
                  description: "O'z sohasining mutaxassislari bo'lgan tajribali o'qituvchilardan ta'lim oling.",
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  context,
                  icon: Icons.analytics,
                  title: "Doimiy Nazorat",
                  description: "O'quvchi o'zlashtirishini real vaqt rejimida kuzatib boring va tahlil qiling.",
                  color: Colors.green,
                ),

                const SizedBox(height: 48),

                // --- APPLICATION BUTTON ---
                ElevatedButton(
                  onPressed: () => _showApplicationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                       Text(
                        "Kursga yozilish",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                       SizedBox(width: 12),
                       Icon(Icons.assignment_ind_rounded),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Aloqa ma'lumotlari"),
                        content: const Text("Tel: +998 88 520 30 30\nTelegram: @unity4_manager\nManzil: Namangan shaxar A.Navoiy ko'chasi Ucell binosi"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Yopish")),
                        ],
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.primary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Biz haqimizda", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Login Sahifasiga Qaytish", style: TextStyle(color: Colors.grey.shade600)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {required IconData icon, required String title, required String description, required Color color}) {
    final theme = Theme.of(context);
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildSimpleStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
