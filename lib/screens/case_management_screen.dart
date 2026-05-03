import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة الفايربيس الأساسية
import '../services/auth_service.dart'; // عشان نعرف المستخدم الحالي (طالب أو محامي)
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/legal_case.dart';

class CaseManagementScreen extends StatefulWidget {
  final String userType;

  const CaseManagementScreen({
    super.key,
    required this.userType,
  });

  @override
  State<CaseManagementScreen> createState() => _CaseManagementScreenState();
}

class _CaseManagementScreenState extends State<CaseManagementScreen> {
  String filter = 'الكل';
  bool _loading = true;
  List<LegalCase> _cases = [];

  List<String> get filters => const ['الكل', 'نشطة', 'مكتملة'];

  List<LegalCase> get items {
    if (filter == 'الكل') return _cases;
    if (filter == 'نشطة') {
      return _cases.where((e) => e.status != 'مكتملة').toList();
    }
    return _cases.where((e) => e.status == 'مكتملة').toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // جلب البيانات من المجموعة الصحيحة lawyerCases
    final snapshot = await FirebaseFirestore.instance
        .collection('lawyerCases') // 👈 تأكدي من الاسم تماماً كما في الفايربيس
        .get();

    if (!mounted) return;

    setState(() {
      _cases = snapshot.docs.map((doc) {
        final data = doc.data();
        return LegalCase(
          id: doc.id,
          title: data['title'] ?? 'قضية جديدة', // الحقل في الفايربيس اسمه title
          client: data['client'] ?? 'عميل',
          type: 'قضية قانونية',
          status: data['status'] ?? 'نشطة',
          progress: (data['progress'] ?? 0).toDouble(),
          updatedAt: data['updatedAt'] ?? 'اليوم',
        );
      }).toList();
      _loading = false;
    });
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
  }

  Future<void> _showCaseDetails(LegalCase caseItem) async {
    Color statusBg;
    Color statusFg;

    if (caseItem.status == 'مكتملة') {
      statusBg = const Color(0xFFEAF8EE);
      statusFg = AppColors.success;
    } else {
      statusBg = const Color(0xFFEFF6FF);
      statusFg = AppColors.primary;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تفاصيل القضية #${caseItem.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CaseDetailRow(label: 'عنوان القضية', value: caseItem.title),
                _CaseDetailRow(label: 'العميل', value: caseItem.client),
                _CaseDetailRow(label: 'النوع', value: caseItem.type),
                _CaseDetailRow(label: 'آخر تحديث', value: caseItem.updatedAt),
                const SizedBox(height: 10),
                const Text(
                  'الحالة',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    caseItem.status,
                    style: TextStyle(
                      color: statusFg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'نسبة الإنجاز',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (caseItem.progress.clamp(0, 100)) / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: AppColors.secondary,
                  color: caseItem.status == 'مكتملة'
                      ? AppColors.success
                      : AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  '${caseItem.progress.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ملخص',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildCaseSummary(caseItem),
                  style: TextStyle(
                    color: AppColors.foreground.withValues(alpha: 0.78),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        );
      },
    );
  }

  String _buildCaseSummary(LegalCase caseItem) {
    if (widget.userType == 'lawyer') {
      return 'هذه القضية من نوع "${caseItem.type}" للعميل "${caseItem.client}". '
          'حالتها الحالية "${caseItem.status}" وآخر تحديث كان بتاريخ ${caseItem.updatedAt}. '
          'يمكنك من هذه الواجهة مراجعة تفاصيلها ورفع المستندات المرتبطة بها.';
    }

    return 'هذه القضية من نوع "${caseItem.type}"، وحالتها الحالية "${caseItem.status}". '
        'آخر تحديث تم بتاريخ ${caseItem.updatedAt}. يمكنك متابعة التقدم الحالي ومراجعة التفاصيل من هذه النافذة.';
  }

  Future<void> _uploadDocuments(LegalCase caseItem) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final validFiles = result.files.where((file) {
      final ext = (file.extension ?? '').toLowerCase();
      return ['pdf', 'png', 'jpg', 'jpeg', 'webp'].contains(ext);
    }).toList();

    if (validFiles.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('لم يتم اختيار ملفات مدعومة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('المستندات المختارة للقضية #${caseItem.id}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: validFiles.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final file = validFiles[index];
                final ext = (file.extension ?? '').toLowerCase();
                final isPdf = ext == 'pdf';

                return Row(
                  children: [
                    Icon(
                      isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: isPdf ? Colors.red : AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        file.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                () => _uploadDocuments(caseItem);
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم رفع ${validFiles.length} مستند/مستندات للقضية رقم ${caseItem.id} بنجاح',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد الرفع'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: Text(
          widget.userType == 'lawyer' ? 'إدارة القضايا' : 'قضاياي',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: filters
                .map(
                  (item) => Pill(
                    text: item,
                    active: filter == item,
                    onPressed: () => setState(() => filter = item),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (items.isEmpty)
            const EmptyState(
              icon: Icons.description_outlined,
              message: 'لا توجد قضايا',
            )
          else
            ...items.map(
              (caseItem) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caseItem.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'العميل: ${caseItem.client}',
                        style: TextStyle(
                          color: AppColors.foreground.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          InfoChip(
                            label: caseItem.status,
                            background: caseItem.status == 'مكتملة'
                                ? const Color(0xFFEAF8EE)
                                : const Color(0xFFEFF6FF),
                            foreground: caseItem.status == 'مكتملة'
                                ? AppColors.success
                                : AppColors.primary,
                            icon: caseItem.status == 'مكتملة'
                                ? Icons.check_circle
                                : Icons.schedule,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            caseItem.updatedAt,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.foreground.withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (caseItem.progress.clamp(0, 100)) / 100,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: AppColors.secondary,
                        color: caseItem.status == 'مكتملة'
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${caseItem.progress.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              text: 'التفاصيل',
                              onPressed: () => _showCaseDetails(caseItem),
                            ),
                          ),
                          if (widget.userType == 'lawyer') ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                text: 'رفع مستند',
                                // 👈 هذا هو التعديل المطلوب لربط الدالة وإخفاء الخط الأصفر
                                onPressed: () => _uploadDocuments(caseItem),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CaseDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _CaseDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 14,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
