import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_plan.dart';

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKey = 'curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "OpenAI-Organization: org-esGTERT2oewDLYZCa51IHKg8" \
  -H "OpenAI-Project: $PROJECT_ID"'; // Replace with your actual API key

  static Future<String> generateFeedback(DailyPlan dailyPlan) async {
    try {
      final completedGoals = dailyPlan.goals.where((goal) => goal.isCompleted).length;
      final totalGoals = dailyPlan.goals.length;
      final completionRate = dailyPlan.completionRate;

      final prompt = '''
Bugün ${dailyPlan.date.day}/${dailyPlan.date.month}/${dailyPlan.date.year} tarihinde kullanıcının hedefleri:

${dailyPlan.goals.map((goal) => '${goal.isCompleted ? '✅' : '❌'} ${goal.title}').join('\n')}

Tamamlanan hedef sayısı: $completedGoals/$totalGoals
Tamamlanma oranı: ${(completionRate * 100).toStringAsFixed(0)}%

Lütfen bu bilgilere dayanarak kullanıcıya kısa, motive edici ve Türkçe bir geri bildirim yazın. 
Geri bildirim şu özelliklere sahip olmalı:
- 2-3 cümle uzunluğunda
- Pozitif ve motive edici
- Başarıları vurgulayan
- Eksik kalan hedefler için yapıcı öneriler sunan
- Kişisel ve samimi bir ton kullanan

Sadece geri bildirim metnini döndürün, başka açıklama eklemeyin.
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Sen motive edici ve pozitif bir AI asistanısın. Kullanıcıların günlük hedeflerini değerlendirip onlara yapıcı geri bildirim veriyorsun.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final feedback = data['choices'][0]['message']['content'].trim();
        return feedback;
      } else {
        // Fallback feedback if API fails
        return _generateFallbackFeedback(completionRate);
      }
    } catch (e) {
      // Fallback feedback if there's an error
      return _generateFallbackFeedback(dailyPlan.completionRate);
    }
  }

  static String _generateFallbackFeedback(double completionRate) {
    if (completionRate >= 1.0) {
      return "Mükemmel! Bugün tüm hedeflerinizi başarıyla tamamladınız. Bu harika bir başarı! 🎉";
    } else if (completionRate >= 0.7) {
      return "Harika bir gün geçirdiniz! Çoğu hedefinizi tamamladınız. Yarın daha da iyisini yapabilirsiniz! 💪";
    } else if (completionRate >= 0.4) {
      return "Bugün bazı hedeflerinizi tamamladınız. Her küçük adım önemlidir. Yarın daha fazlasını başarabilirsiniz! 🌟";
    } else {
      return "Bugün zorlu bir gündü, ama yarın yeni bir başlangıç yapabilirsiniz. Her gün yeni bir fırsattır! 🌅";
    }
  }
} 