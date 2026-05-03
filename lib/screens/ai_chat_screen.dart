import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart'; // تم تعطيله مؤقتاً لتقليل التحذيرات إذا لم تستخدميه
import '../services/auth_service.dart';
import '../core/theme/app_colors.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';
import 'package:firebase_auth/firebase_auth.dart';

// كلاس المرفقات المحلي
class _PickedAttachment {
  final String id;
  final String name;
  final Uint8List? bytes;
  final bool isPdf;
  final String readableSize;

  _PickedAttachment({
    required this.id,
    required this.name,
    this.bytes,
    required this.isPdf,
    required this.readableSize,
  });

  bool get isImage => !isPdf;

  static _PickedAttachment? fromPlatformFile(PlatformFile file) {
    if (file.bytes == null) return null;
    return _PickedAttachment(
      id: '${file.name}_${DateTime.now().microsecondsSinceEpoch}',
      name: file.name,
      bytes: file.bytes,
      isPdf: file.extension?.toLowerCase() == 'pdf',
      readableSize: '${(file.size / 1024).toStringAsFixed(1)} KB',
    );
  }
}

class AIChatScreen extends StatefulWidget {
  final String userType;

  const AIChatScreen({
    super.key,
    required this.userType,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final GeminiService _geminiService = GeminiService();

  final List<ChatMessage> _messages = [];
  final List<_PickedAttachment> _pendingAttachments = [];
  bool _sending = false;

  final List<String> _suggestions = const [
    'ما هي حقوقي في عقد العمل؟',
    'كيف أرفع دعوى قضائية؟',
    'ما خطوات توثيق اتفاقية؟',
    'متى يحق فسخ العقد؟',
    'ما الفرق بين البلاغ والدعوى؟',
  ];

  @override
  void initState() {
    super.initState();
    // 👈 تعديل السطر 75: إضافة الخصائص المطلوبة للمودل
    _messages.add(
      ChatMessage(
        id: 'welcome',
        senderId: 'ai',
        text: 'مرحبًا بك في الاستشارات الذكية. اكتب سؤالك وسأجيبك فوراً.',
        isUser: false,
        timestamp: DateTime.now(),
        hasAttachments: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- دوال المرفقات ---
  Future<void> _pickImages() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: true, withData: true);
    if (result != null) {
      setState(() {
        _pendingAttachments.addAll(result.files
            .map((f) => _PickedAttachment.fromPlatformFile(f))
            .whereType<_PickedAttachment>());
      });
    }
  }

  Future<void> _pickPdfFiles() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true);
    if (result != null) {
      setState(() {
        _pendingAttachments.addAll(result.files
            .map((f) => _PickedAttachment.fromPlatformFile(f))
            .whereType<_PickedAttachment>());
      });
    }
  }

  // --- الإرسال والربط ---
  Future<void> _sendMessage([String? preset]) async {
    ;
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty && _pendingAttachments.isEmpty || _sending) return;
    final currentUser = await _authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() => _sending = true);

    // 1. استخراج النصوص من ملفات الـ PDF إذا وجدت
    String extractedContext = "";
    for (var file in _pendingAttachments) {
      if (file.isPdf && file.bytes != null) {
        final pdfText = await _extractPdfText(
            file.bytes!); // نستخدم الدالة التي عرفناها سابقاً
        extractedContext += "\nمحتوى ملف ${file.name}:\n$pdfText\n";
      }
    }

    // 2. تجهيز الطلب النهائي لـ Gemini (سؤال المستخدم + محتوى الملفات)
    final fullPrompt = text.isEmpty
        ? "حلل هذه الملفات وأعطني ملخصاً قانونياً:\n$extractedContext"
        : "بناءً على الملفات التالية:\n$extractedContext\n\nأجب على هذا السؤال: $text";

    _controller.clear();
    final hasAttachments = _pendingAttachments.isNotEmpty;
    _pendingAttachments.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 3. إرسال الطلب المدعم بالبيانات لـ Gemini
    final reply = await _geminiService.sendLegalPrompt(
        prompt: fullPrompt, userType: widget.userType);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    // 4. الحفظ في الفايربيس
    await FirebaseFirestore.instance.collection('AIChats').add({
      'userId': FirebaseAuth.instance.currentUser?.uid ?? "",
      'userPrompt':
          text.isEmpty ? "تحليل ملفات" : text, // حفظ السؤال الأصلي للمستخدم
      'aiResponse': reply,
      'hasAttachments': hasAttachments, // تأكيد وجود مرفقات في السجل
      'timestamp': FieldValue.serverTimestamp(),
      'userType': widget.userType,
    });

    if (mounted) setState(() => _sending = false);
  }

  // دالة استخراج النص من ملفات الـ PDF
  Future<String> _extractPdfText(Uint8List bytes) async {
    PdfDocument? document;
    try {
      // فتح ملف الـ PDF من البيانات (Bytes)
      document = await PdfDocument.openData(bytes);

      final buffer = StringBuffer();

      // المرور على كل صفحات الملف واستخراج النصوص
      for (final page in document.pages) {
        final rawText = await page.loadText();
        final text = rawText.fullText.trim();
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln('\n');
          }
          buffer.writeln(text);
        }
      }

      final fullText = buffer.toString().trim();

      // إذا كان النص طويلاً جداً، نأخذ أول 3000 حرف لضمان سرعة الرد من Gemini
      if (fullText.length > 3000) {
        return fullText.substring(0, 3000);
      }

      return fullText;
    } catch (e) {
      debugPrint("خطأ في استخراج نص الـ PDF: $e");
      return '';
    } finally {
      // إغلاق الملف لتحرير الذاكرة
      await document?.dispose();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('المساعد القانوني AI',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.white)),
          centerTitle: true,
          // 👈 تعديل: زر الرجوع
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('AIChats')
                    .orderBy('timestamp',
                        descending:
                            true) // هذا التعديل يخلي أحدث رسالة تجي أول وحدة
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(child: Text('ابدأ المحادثة الآن...'));

                  // 💡 ترتيب الرسائل برمجياً داخل التطبيق لتجنب مشكلة الـ Null في السيرفر
                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    itemCount: docs.length,
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return Column(
                        key: ValueKey(docs[index].id),
                        children: [
                          ChatBubble(
                            text: data['userPrompt'] ?? '',
                            isUser: true,
                          ),
                          if (data['aiResponse'] != null &&
                              data['aiResponse'].toString().isNotEmpty)
                            ChatBubble(
                              text: data['aiResponse'] ?? '',
                              isUser: false,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            if (_sending) _buildTypingIndicator(),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(text,
            style: TextStyle(
                fontFamily: 'Cairo',
                color: isUser ? Colors.white : AppColors.foreground)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Image.asset('assets/images/ai_avatar.png',
              width: 30,
              height: 30,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.auto_awesome, color: AppColors.primary)),
          const SizedBox(width: 10),
          const Text('المساعد يفكر...',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
              onPressed: _openAttachmentPicker, // 👈 تعديل لفتح الخيارات
              icon: const Icon(Icons.attach_file, color: AppColors.primary)),
          Expanded(
              child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                      hintText: 'اسأل هنا...', border: InputBorder.none))),
          IconButton(
              onPressed: () => _sendMessage(),
              icon: const Icon(Icons.send, color: AppColors.primary)),
        ],
      ),
    );
  }

  // 👈 إضافة دالة لاختيار نوع المرفق
  void _openAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('صور'),
            onTap: () {
              Navigator.pop(context);
              _pickImages();
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('ملفات PDF'),
            onTap: () {
              Navigator.pop(context);
              _pickPdfFiles();
            },
          ),
        ],
      ),
    );
  }
}

// 👈 تعريف الكلاس المستقل لفقاعة المحادثة لتحسين الأداء
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      // المحاذاة: يسار للمستخدم، ويمين للذكاء الاصطناعي
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          // لون أزرق للمستخدم وأبيض للذكاء الاصطناعي
          color: isUser ? const Color(0xFF1E3A5F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? Radius.zero : const Radius.circular(18),
            bottomRight: isUser ? const Radius.circular(18) : Radius.zero,
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.5,
            height: 1.4,
            color: isUser ? Colors.white : const Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }
}
