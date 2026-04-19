import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GeminiService {
  final http.Client _client;

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> sendLegalPrompt({
    required String prompt,
    required String userType,
  }) async {
    final trimmedPrompt = prompt.trim();

    if (trimmedPrompt.isEmpty) {
      return 'يرجى كتابة سؤالك القانوني أولًا.';
    }

    if (!AppConfig.hasGeminiKey) {
      return _fallbackResponse(trimmedPrompt);
    }

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
      );

      final systemInstruction = '''
أنت مساعد قانوني ذكي داخل تطبيق "محاميك".

مهمتك:
- الإجابة عن السؤال القانوني الحالي مباشرة.
- عدم تكرار التحية أو تقديم نفسك في كل رد.
- عدم قول "أهلاً بك" أو "أنا مساعد قانوني" إلا إذا طلب المستخدم التعريف بك.
- إعطاء جواب عملي وواضح ومباشر.
- إذا كان السؤال عن نظام العمل أو العقود أو الفصل أو الاستقالة أو الحقوق، فأجب بنقاط مرتبة وواضحة.
- إذا كانت التفاصيل ناقصة، اذكر الافتراضات واطلب المعلومة الناقصة باختصار.
- لا تعطِ حكمًا نهائيًا قاطعًا.
- لا تكرر التنبيه القانوني إلا مرة واحدة في آخر الرد وباختصار.
- اجعل الرد بالعربية الواضحة المناسبة للمستخدم العادي.
- إذا احتوى السؤال على نص مستخرج من PDF أو وصف مرفقات، فحلله وابدأ بالإجابة مباشرة.
- لا تُرجع ردًا عامًا أو ترحيبيًا إذا كان السؤال محددًا.

نوع المستخدم الحالي: $userType
''';

      final body = {
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': trimmedPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.25,
          'topK': 32,
          'topP': 0.9,
          'maxOutputTokens': 900,
        }
      };

      final response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as Map<String, dynamic>;

        final text = _extractTextFromGeminiResponse(decoded);

        if (text.isNotEmpty) {
          return _postProcessAnswer(text);
        }

        return _fallbackResponse(trimmedPrompt);
      }

      return _fallbackResponse(trimmedPrompt);
    } catch (_) {
      return _fallbackResponse(trimmedPrompt);
    }
  }

  String _extractTextFromGeminiResponse(Map<String, dynamic> data) {
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return '';
    }

    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      return '';
    }

    final content = first['content'];
    if (content is! Map<String, dynamic>) {
      return '';
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final value = part['text']?.toString().trim();
        if (value != null && value.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln();
          }
          buffer.write(value);
        }
      }
    }

    return buffer.toString().trim();
  }

  String _postProcessAnswer(String text) {
    var answer = text.trim();

    if (answer.isEmpty) {
      return 'تعذر توليد إجابة واضحة حاليًا. حاول إعادة صياغة السؤال.';
    }

    final lines = answer
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final filtered = <String>[];

    for (final line in lines) {
      final normalized = line.replaceAll('\"', '').replaceAll('“', '').replaceAll('”', '');

      final isRepeatedIntro =
          normalized.contains('أهلاً بك في تطبيق') ||
          normalized.contains('أنا مساعد قانوني ذكي') ||
          normalized.contains('هنا لتقديم معلومات قانونية عامة');

      if (!isRepeatedIntro) {
        filtered.add(line);
      }
    }

    answer = filtered.join('\n').trim();

    if (answer.isEmpty) {
      answer = text.trim();
    }

    if (!answer.contains('لا تغني عن استشارة محام')) {
      answer =
          '$answer\n\n⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص.';
    }

    return answer;
  }

  String _fallbackResponse(String prompt) {
    final p = prompt.toLowerCase();

    if (p.contains('استقال') ||
        p.contains('فصل') ||
        p.contains('انتهاء') ||
        p.contains('عقد العمل') ||
        p.contains('عمل') ||
        p.contains('موظف')) {
      return '''
يعتمد ذلك على سبب الإنهاء وطبيعة العقد والمدة المتبقية منه، لكن بشكل عام:

1. إذا كان العقد محدد المدة وتم إنهاؤه قبل انتهائه دون سبب مشروع، فقد تترتب تعويضات أو حقوق بحسب سبب الإنهاء وبنود العقد.
2. إذا وُجد حظر أو شرط تعاقدي بعد انتهاء العلاقة العمالية، فيجب فحص مشروعيته ومدته ونطاقه والمقابل المرتبط به.
3. في القضايا العمالية عادة تتم مراجعة:
- عقد العمل
- سبب الإنهاء
- تاريخ بداية ونهاية العقد
- الإشعار
- المستحقات
- أي شرط عدم منافسة أو حظر
4. لا يمكن الجزم بصحة رفع المطالبة أو قبولها قبل مراجعة نص العقد وبند الحظر وسبب إنهاء العلاقة.

أرسل لي:
- هل العقد محدد أم غير محدد؟
- من الذي أنهى العلاقة؟
- ما نص شرط الحظر أو المنع؟
- هل يوجد إشعار أو مخالصة أو إنهاء رسمي؟

⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص.
''';
    }

    if (p.contains('عقد') || p.contains('اتفاقية')) {
      return '''
في مراجعة العقود، ركّز على:

1. بيانات الأطراف.
2. محل العقد.
3. المدة.
4. المقابل المالي.
5. الالتزامات.
6. الفسخ.
7. الشرط الجزائي.
8. جهة حل النزاع.

إذا رغبت، انسخ لي البند أو الفقرة محل الإشكال وسأشرحها لك بشكل أوضح.

⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص.
''';
    }

    if (p.contains('طلاق') || p.contains('نفقة') || p.contains('حضانة')) {
      return '''
في مسائل الأحوال الشخصية، يلزم عادة معرفة:

1. نوع الطلب: طلاق أو نفقة أو حضانة أو زيارة.
2. وجود أبناء وأعمارهم.
3. وجود حكم سابق أو لا.
4. المستندات الداعمة.
5. محل الإقامة والوقائع الأساسية.

اكتب لي تفاصيل الحالة وسأرتب لك جوابًا أوضح.

⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص.
''';
    }

    return '''
حتى أجيبك بشكل أدق، أرسل لي:
1. نوع القضية.
2. الوقائع باختصار.
3. هل يوجد عقد أو إشعار أو مستند؟
4. ما النتيجة التي تريد الوصول إليها؟

⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص.
''';
  }

  void dispose() {
    _client.close();
  }
}