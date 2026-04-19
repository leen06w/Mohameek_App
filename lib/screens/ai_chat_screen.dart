import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/theme/app_colors.dart';
import '../services/gemini_service.dart';

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
  final GeminiService _geminiService = GeminiService();

  final List<_ChatMessage> _messages = [];
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
    _messages.add(
      const _ChatMessage(
        text:
            'مرحبًا بك في الاستشارات القانونية الذكية.\n\nاكتب سؤالك القانوني وسأقدم لك معلومات عامة مرتبة وواضحة.\n\nيمكنك أيضًا إرفاق صور وملفات PDF متعددة مع رسالتك.',
        isUser: false,
        attachments: [],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _geminiService.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final items = result.files
        .map(_PickedAttachment.fromPlatformFile)
        .whereType<_PickedAttachment>()
        .toList();

    if (items.isEmpty) return;

    setState(() {
      _pendingAttachments.addAll(items);
    });
  }

  Future<void> _pickPdfFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final items = result.files
        .map(_PickedAttachment.fromPlatformFile)
        .whereType<_PickedAttachment>()
        .toList();

    if (items.isEmpty) return;

    setState(() {
      _pendingAttachments.addAll(items);
    });
  }

  Future<String> _extractPdfText(Uint8List bytes) async {
    PdfDocument? document;
    try {
      document = await PdfDocument.openData(bytes);

      final buffer = StringBuffer();

      for (final page in document.pages) {
        final rawText = await page.loadText();
        final text = rawText?.fullText.trim() ?? '';
        if (text.isNotEmpty) {
          if (buffer.isNotEmpty) {
            buffer.writeln('\n');
          }
          buffer.writeln(text);
        }
      }

      final fullText = buffer.toString().trim();

      if (fullText.isEmpty) {
        return '';
      }

      if (fullText.length > 3000) {
        return fullText.substring(0, 3000);
      }

      return fullText;
    } catch (_) {
      return '';
    } finally {
      await document?.dispose();
    }
  }

  void _removePendingAttachment(String id) {
    setState(() {
      _pendingAttachments.removeWhere((item) => item.id == id);
    });
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    final hasText = text.isNotEmpty;
    final hasAttachments = _pendingAttachments.isNotEmpty;

    if ((!hasText && !hasAttachments) || _sending) return;

    final userAttachments = List<_PickedAttachment>.from(_pendingAttachments);

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          attachments: userAttachments,
        ),
      );
      _sending = true;
      _controller.clear();
      _pendingAttachments.clear();
    });

    _scrollToBottom();

    final attachmentSummary = await _buildAttachmentSummaryForPrompt(
      userAttachments,
    );

    final composedPrompt = _composePrompt(
      text: text,
      attachmentSummary: attachmentSummary,
    );

    final reply = await _geminiService.sendLegalPrompt(
      prompt: composedPrompt,
      userType: widget.userType,
    );

    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: reply,
          isUser: false,
          attachments: const [],
        ),
      );
      _sending = false;
    });

    _scrollToBottom();
  }

  String _composePrompt({
    required String text,
    required String attachmentSummary,
  }) {
    if (text.isEmpty && attachmentSummary.isNotEmpty) {
      return '''
لدى المستخدم مرفقات فقط بدون نص.
$attachmentSummary

أعطه ردًا قانونيًا أوليًا مهنيًا ومختصرًا، واطلب منه توضيح سؤاله القانوني المرتبط بالمرفقات.
''';
    }

    if (attachmentSummary.isEmpty) {
      return text;
    }

    return '''
السؤال القانوني من المستخدم:
$text

تفاصيل المرفقات:
$attachmentSummary

أجب بالعربية بشكل منظم وواضح، واذكر أن التقييم النهائي للمستندات أو الصور يحتاج مراجعة قانونية مباشرة عند الحاجة.
''';
  }

  Future<String> _buildAttachmentSummaryForPrompt(
    List<_PickedAttachment> attachments,
  ) async {
    if (attachments.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('عدد المرفقات: ${attachments.length}');
    buffer.writeln('تفاصيل المرفقات:');

    for (final item in attachments) {
      final type = item.isPdf ? 'PDF' : 'صورة';
      buffer.writeln('- $type: ${item.name} (${item.readableSize})');
    }

    final pdfAttachments =
        attachments.where((item) => item.isPdf && item.bytes != null).toList();

    for (final item in pdfAttachments) {
      final extractedText = await _extractPdfText(item.bytes!);
      if (extractedText.isNotEmpty) {
        buffer.writeln('\nمحتوى مستخرج من الملف ${item.name}:');
        buffer.writeln(extractedText);
      } else {
        buffer.writeln(
          '\nتعذر استخراج نص واضح من الملف ${item.name}. قد يكون ممسوحًا ضوئيًا أو محميًا.',
        );
      }
    }

    return buffer.toString().trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  void _openAttachmentPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickerActionTile(
                  icon: Icons.image_outlined,
                  title: 'إرفاق صور متعددة',
                  subtitle: 'اختر صورة واحدة أو عدة صور',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImages();
                  },
                ),
                const SizedBox(height: 12),
                _PickerActionTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'إرفاق ملفات PDF متعددة',
                  subtitle: 'اختر ملف PDF واحد أو أكثر',
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickPdfFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
            const Spacer(),
            Column(
              children: [
                const Text(
                  'الاستشارات القانونية AI',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'متصل الآن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          return InkWell(
            onTap: () => _sendMessage(item),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text(
                  item,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingAttachments() {
    if (_pendingAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المرفقات الجاهزة للإرسال',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingAttachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _pendingAttachments[index];
                return _PendingAttachmentCard(
                  attachment: item,
                  onRemove: () => _removePendingAttachment(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 6 : 20),
            bottomRight: Radius.circular(isUser ? 20 : 6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (message.attachments.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.attachments
                    .map(
                      (item) => _SentAttachmentChip(
                        attachment: item,
                        isUser: isUser,
                      ),
                    )
                    .toList(),
              ),
              if (message.text.trim().isNotEmpty) const SizedBox(height: 10),
            ],
            if (message.text.trim().isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.8,
                  color: isUser ? Colors.white : AppColors.foreground,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 130),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypingDot(),
            SizedBox(width: 5),
            _TypingDot(),
            SizedBox(width: 5),
            _TypingDot(),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSuggestions(),
          const SizedBox(height: 12),
          _buildPendingAttachments(),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: _sending ? null : _openAttachmentPickerSheet,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك القانوني هنا...',
                    hintStyle: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _sending
                      ? AppColors.secondary
                      : AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppColors.primary,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '⚠ هذه معلومات قانونية عامة ولا تغني عن استشارة محامٍ مرخّص',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _messages.length + (_sending ? 1 : 0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Container(
                color: AppColors.background,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (_sending && index == _messages.length) {
                      return _buildTypingBubble();
                    }

                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<_PickedAttachment> attachments;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.attachments,
  });
}

class _PickedAttachment {
  final String id;
  final String name;
  final String extension;
  final int size;
  final Uint8List? bytes;

  const _PickedAttachment({
    required this.id,
    required this.name,
    required this.extension,
    required this.size,
    required this.bytes,
  });

  bool get isPdf => extension.toLowerCase() == 'pdf';

  bool get isImage {
    const imageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'];
    return imageExtensions.contains(extension.toLowerCase());
  }

  String get readableSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static _PickedAttachment? fromPlatformFile(PlatformFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    if (ext.isEmpty) return null;

    final allowed = ext == 'pdf' ||
        ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'gif' ||
        ext == 'bmp';

    if (!allowed) return null;

    return _PickedAttachment(
      id: '${file.name}_${DateTime.now().microsecondsSinceEpoch}',
      name: file.name,
      extension: ext,
      size: file.size,
      bytes: file.bytes,
    );
  }
}

class _PendingAttachmentCard extends StatelessWidget {
  final _PickedAttachment attachment;
  final VoidCallback onRemove;

  const _PendingAttachmentCard({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = attachment.isImage && attachment.bytes != null;

    return SizedBox(
      width: 110,
      child: Stack(
        children: [
          Container(
            width: 110,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: hasPreview
                        ? Image.memory(
                            attachment.bytes!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            color: AppColors.background,
                            child: Icon(
                              attachment.isPdf
                                  ? Icons.picture_as_pdf_rounded
                                  : Icons.insert_drive_file_rounded,
                              size: 34,
                              color: AppColors.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attachment.readableSize,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentAttachmentChip extends StatelessWidget {
  final _PickedAttachment attachment;
  final bool isUser;

  const _SentAttachmentChip({
    required this.attachment,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isUser ? Colors.white : AppColors.primary;
    final background = isUser
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.background;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.image_rounded,
            size: 18,
            color: foreground,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              attachment.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground.withValues(alpha: 0.60),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}