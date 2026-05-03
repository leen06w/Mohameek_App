import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class GeminiService {
  final http.Client _client = http.Client();

  Future<String> _getRelevantLaw(String prompt) async {
    String fileName = '';
    if (prompt.contains('موظف') ||
        prompt.contains('عمل') ||
        prompt.contains('مكافأة')) {
      fileName = 'labor_law.txt';
    } else if (prompt.contains('شركة') || prompt.contains('سجل')) {
      fileName = 'companies_law.txt';
    } else if (prompt.contains('عقد') || prompt.contains('بيع')) {
      fileName = 'civil_transactions_law.txt';
    } else if (prompt.contains('جريمة') || prompt.contains('شرطة')) {
      fileName = 'penal_procedures_law.txt';
    } else if (prompt.contains('توقيع') || prompt.contains('إلكتروني')) {
      fileName = 'electronic_transactions_law.txt';
    }
    if (fileName.isEmpty) return "";
    try {
      return await rootBundle.loadString('assets/legal_docs/$fileName');
    } catch (e) {
      return "";
    }
  }

  Future<String> sendLegalPrompt(
      {required String prompt, required String userType}) async {
    final String apiKey =
        "**********************************"; //المفتاح هنا ينحط
    final String cleanKey = apiKey.trim();

    // الحل النهائي للرابط لضمان عدم ظهور 404
    final String fullUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=$cleanKey';
    final lawContext = await _getRelevantLaw(prompt);

    final systemInstruction = lawContext.isNotEmpty
        ? "أنت محامٍ سعودي خبير. بناءً على النظام التالي:\n$lawContext\nأجب بدقة."
        : "أنت محامٍ سعودي خبير. أجب بناءً على الأنظمة السعودية المعمول بها.";

    // تبسيط الهيكل لضمان القبول السريع وتقليل الضغط على المعالج
    // داخل دالة إرسال الطلب في ملف gemini_service.dart
    final Map<String, dynamic> body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {
              "text": """
أنت الآن "المستشار القانوني الذكي"، نظام متطور لتحليل الأنظمة واللوائح السعودية.
تعليمات الإجابة:
1. الرد باللغة العربية الفصحى وبأسلوب قانوني رصين ومحايد.
2. استخدام التنسيق (Bold للعناوين، وقوائم مرقمة أو نقطية للأنظمة).
3. عند الإجابة، استند إلى الأنظمة السعودية ذات العلاقة (مثل نظام العمل، نظام التعاملات الإلكترونية، إلخ).
4. إذا كان السؤال يحتاج لتفاصيل أكثر، اطلب من المستخدم توضيحها.
5. اختم الرد دائماً بعبارة: "هذا التحليل تم بواسطة الذكاء الاصطناعي كاستشارة استرشادية، ويرجى الرجوع للمراجع القانونية الرسمية".

السؤال هو: $prompt
"""
            }
          ]
        }
      ],
      "generationConfig": {
        "thinkingConfig": {"thinkingLevel": "HIGH"}
      }
    };

    try {
      final response = await _client.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print("Gemini Error: ${response.statusCode}");
        return 'عذراً، واجهت مشكلة في الاتصال بالذكاء الاصطناعي.';
      }
    } catch (e) {
      return 'حدث خطأ في الشبكة، يرجى المحاولة لاحقاً.';
    }
  }

  void dispose() => _client.close();
}
