import 'dart:convert';
import 'package:http/http.dart' as http;

class TelegramService {
  static const String _token = '8584272614:AAH5XBuii0VeFh-9IvLtvpCxmp7BeP6ejtY';
  // Admin Chat ID (Odatda shaxsiy ID yoki guruh ID bo'ladi)
  // Hozircha bu yerga o'z IDingizni yozishingiz kerak.
  static const String _chatId = '7999358209'; // UNITY4 Manager Chat ID

  static Future<void> sendApplicationNotification({
    required String name,
    required String phone,
    required String course,
    String? note,
  }) async {
    final String message = "🚀 *Yangi Kurs Arizasi!*\n\n"
        "👤 *Ism:* $name\n"
        "📞 *Tel:* $phone\n"
        "📚 *Kurs:* ${course.isEmpty ? 'Belgilanmagan' : course}\n"
        "📝 *Izoh:* ${note ?? 'Yo\'q'}\n\n"
        "⏰ *Vaqt:* ${DateTime.now().toString().substring(0, 16)}";

    try {
      final url = Uri.parse('https://api.telegram.org/bot$_token/sendMessage');
      await http.post(
        url,
        body: {
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'Markdown',
        },
      );
    } catch (e) {
      print('Telegram error: $e');
    }
  }

  // Chat IDni aniqlash uchun yordamchi metod (faqat bir marta ishlatish uchun)
  static Future<String?> getLatestChatId() async {
    try {
      final url = Uri.parse('https://api.telegram.org/bot$_token/getUpdates');
      final response = await http.get(url);
      final data = json.decode(response.body);
      if (data['ok'] == true && data['result'].isNotEmpty) {
        return data['result'].last['message']['chat']['id'].toString();
      }
    } catch (e) {
      print('Telegram find id error: $e');
    }
    return null;
  }
}
