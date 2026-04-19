import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/location_links.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../data/mock_data.dart';
import '../models/lawyer.dart';
import '../services/requests_service.dart';

class BookingDetails {
  final Lawyer lawyer;
  final String consultationType;
  final String date;
  final String time;
  final String description;
  final String caseType;
  final String price;

  const BookingDetails({
    required this.lawyer,
    required this.consultationType,
    required this.date,
    required this.time,
    required this.description,
    required this.caseType,
    required this.price,
  });
}

class BookingScreen extends StatefulWidget {
  final Lawyer? lawyer;

  const BookingScreen({super.key, this.lawyer});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _requestsService = RequestsService();

  int step = 1;
  String? selectedType;
  String selectedDate = '';
  String selectedTime = '';
  String caseType = '';
  final TextEditingController descriptionController = TextEditingController();
  bool submitting = false;

  Lawyer? _resolvedLawyer;

  Lawyer get lawyer => _resolvedLawyer ?? MockData.lawyers.first;

  List<Map<String, dynamic>> get consultationTypes => const [
        {
          'key': 'video',
          'label': 'استشارة عن بعد',
          'icon': Icons.videocam_outlined,
        },
        {
          'key': 'phone',
          'label': 'استشارة هاتفية',
          'icon': Icons.phone_outlined,
        },
        {
          'key': 'inperson',
          'label': 'استشارة حضورية',
          'icon': Icons.location_on_outlined,
        },
      ];

  List<String> get caseTypes => const [
        'قضايا تجارية',
        'قضايا أسرية',
        'قضايا عقارية',
        'قضايا جنائية',
        'قضايا عمالية',
        'قضايا إدارية',
      ];

  List<String> get availableDates => const [
        '2026-04-07',
        '2026-04-08',
        '2026-04-09',
        '2026-04-10',
        '2026-04-11',
      ];

  List<String> get availableTimes => const [
        '09:00',
        '10:00',
        '11:00',
        '14:00',
        '15:00',
        '16:00',
        '17:00',
      ];

  bool get canContinue {
    if (step == 1) return selectedType != null;
    if (step == 2) return selectedDate.isNotEmpty && selectedTime.isNotEmpty;
    if (step == 3) return caseType.isNotEmpty;
    if (step == 4) return descriptionController.text.trim().isNotEmpty;
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_resolvedLawyer != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (widget.lawyer != null) {
      _resolvedLawyer = widget.lawyer;
    } else if (args is Lawyer) {
      _resolvedLawyer = args;
    } else if (args is BookingDetails) {
      _resolvedLawyer = args.lawyer;
    } else {
      _resolvedLawyer = MockData.lawyers.first;
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool success = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? AppColors.primary : AppColors.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showCenteredSuccessAndGoToRequests() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFB7E4C7)),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 50,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'تم إرسال الطلب بنجاح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'تم إرسال طلب الاستشارة إلى المحامي بنجاح، وسيتم تحويلك الآن إلى قائمة الطلبات.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    height: 1.7,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.userRequests,
      (route) => false,
    );
  }

  void _next() {
    if (!canContinue) {
      _showValidationMessage();
      return;
    }
    if (step < 4) {
      setState(() => step = step + 1);
    }
  }

  void _previous() {
    if (step > 1) {
      setState(() => step = step - 1);
    }
  }

  void _resetBooking() {
    setState(() {
      step = 1;
      selectedType = null;
      selectedDate = '';
      selectedTime = '';
      caseType = '';
      descriptionController.clear();
    });
    _showMessage('تمت إعادة تعيين بيانات الحجز');
  }

  void _showValidationMessage() {
    String message = 'يرجى إكمال البيانات المطلوبة';

    if (step == 1 && selectedType == null) {
      message = 'يرجى اختيار نوع الاستشارة أولًا';
    } else if (step == 2 && (selectedDate.isEmpty || selectedTime.isEmpty)) {
      message = 'يرجى اختيار التاريخ والوقت';
    } else if (step == 3 && caseType.isEmpty) {
      message = 'يرجى اختيار نوع القضية';
    } else if (step == 4 && descriptionController.text.trim().isEmpty) {
      message = 'يرجى كتابة وصف للمشكلة القانونية';
    }

    _showMessage(message, success: false);
  }

  String get selectedTypeLabel {
    final item = consultationTypes.firstWhere(
      (e) => e['key'] == selectedType,
      orElse: () => {'label': 'غير محدد'},
    );
    return item['label'] as String;
  }

  Future<void> _submitRequest() async {
    if (!canContinue || selectedType == null) {
      _showValidationMessage();
      return;
    }

    setState(() => submitting = true);

    await _requestsService.createRequest({
      'lawyer_id': lawyer.id,
      'lawyer_name': lawyer.name,
      'lawyer_specialty': lawyer.specialty,
      'consultation_type': selectedTypeLabel,
      'preferred_date': selectedDate,
      'preferred_time': selectedTime,
      'case_type': caseType,
      'description': descriptionController.text.trim(),
      'price': lawyer.price,
      'status': 'pending',
      'submitted_at': DateTime.now().toString(),
      'office_name': lawyer.officeName,
      'office_address': lawyer.officeAddress,
      'lat': lawyer.lat,
      'lng': lawyer.lng,
    });

    if (!mounted) return;

    setState(() => submitting = false);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    await _showCenteredSuccessAndGoToRequests();
  }

  Future<void> _openGoogleMapsExternal() async {
    await LocationLinks.openMaps(
      context,
      lat: lawyer.lat,
      lng: lawyer.lng,
    );
  }

  Future<void> _openGoogleEarthExternal() async {
    await LocationLinks.openEarth(
      context,
      lat: lawyer.lat,
      lng: lawyer.lng,
    );
  }

  Future<void> _copyCoordinates() async {
    final coords =
        '${lawyer.lat.toStringAsFixed(6)}, ${lawyer.lng.toStringAsFixed(6)}';

    await Clipboard.setData(
      ClipboardData(text: coords),
    );

    if (!mounted) return;
    _showMessage('تم نسخ الإحداثيات بنجاح');
  }

  Future<void> _copyLocationLink() async {
    await LocationLinks.copyMapsLink(
      context,
      lat: lawyer.lat,
      lng: lawyer.lng,
    );
  }

  Widget _buildElegantMapSection() {
    final coordsText =
        '${lawyer.lat.toStringAsFixed(6)}, ${lawyer.lng.toStringAsFixed(6)}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.officeName,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lawyer.officeAddress,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground.withValues(alpha: 0.65),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lawyer.lat, lawyer.lng),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mahamik.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lawyer.lat, lawyer.lng),
                          width: 46,
                          height: 46,
                          child: const Icon(
                            Icons.location_on,
                            size: 42,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.my_location_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'الإحداثيات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      child: Text(
                        coordsText,
                        textAlign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: 'نسخ الإحداثيات',
                        outlined: true,
                        onPressed: _copyCoordinates,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryButton(
                        text: 'نسخ الرابط',
                        onPressed: _copyLocationLink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: 'Google Earth',
                        outlined: true,
                        onPressed: _openGoogleEarthExternal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        text: 'فتح Google Maps',
                        onPressed: _openGoogleMapsExternal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openLocationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.only(top: 90),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              children: [
                const Center(
                  child: SizedBox(
                    width: 50,
                    child: Divider(thickness: 4),
                  ),
                ),
                const SizedBox(height: 10),
                _buildElegantMapSection(),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'إغلاق',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ملخص الحجز',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'المحامي', value: lawyer.name),
          _SummaryRow(label: 'نوع الاستشارة', value: selectedTypeLabel),
          _SummaryRow(
            label: 'التاريخ',
            value: selectedDate.isEmpty ? 'غير محدد' : selectedDate,
          ),
          _SummaryRow(
            label: 'الوقت',
            value: selectedTime.isEmpty ? 'غير محدد' : selectedTime,
          ),
          _SummaryRow(
            label: 'نوع القضية',
            value: caseType.isEmpty ? 'غير محدد' : caseType,
          ),
          _SummaryRow(label: 'السعر', value: '${lawyer.price} ر.س'),
        ],
      ),
    );
  }

  Widget _buildTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر نوع الاستشارة',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...consultationTypes.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => selectedType = item['key'] as String),
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selectedType == item['key']
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selectedType == item['key']
                        ? AppColors.primary
                        : AppColors.border,
                    width: selectedType == item['key'] ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: selectedType == item['key']
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: selectedType == item['key']
                            ? AppColors.primary
                            : AppColors.foreground,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (selectedType == item['key'])
                      const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر التاريخ والوقت',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18),
            SizedBox(width: 6),
            Text('التاريخ', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableDates.map((date) {
            final dt = DateTime.parse(date);
            final label = '${dt.day}/${dt.month}';
            final active = selectedDate == date;
            return _SelectionTile(
              text: label,
              active: active,
              onTap: () => setState(() => selectedDate = date),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Icon(Icons.schedule_outlined, size: 18),
            SizedBox(width: 6),
            Text('الوقت', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableTimes
              .map(
                (time) => _SelectionTile(
                  text: time,
                  active: selectedTime == time,
                  onTap: () => setState(() => selectedTime = time),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCaseTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر نوع القضية',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        ...caseTypes.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => setState(() => caseType = item),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: caseType == item
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        caseType == item ? AppColors.primary : AppColors.border,
                    width: caseType == item ? 2 : 1,
                  ),
                ),
                child: Text(
                  item,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: caseType == item
                        ? AppColors.primary
                        : AppColors.foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'وصف المشكلة القانونية',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText:
                'اشرح بالتفصيل المشكلة القانونية التي تحتاج استشارة بشأنها...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '* سيتم الحفاظ على سرية المعلومات',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.foreground.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 18),
        _buildSummaryCard(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: const AppHeader(
        title: 'حجز استشارة',
        leadingIcon: Icons.arrow_back,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Row(
                  children: [
                    _StepCircle(number: index + 1, currentStep: step),
                    if (index < 3)
                      Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: step > index + 1
                                ? AppColors.primary
                                : AppColors.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lawyer.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer.specialty,
                        style: TextStyle(
                          color: AppColors.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedType == 'inperson')
                  TextButton.icon(
                    onPressed: _openLocationSheet,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('الموقع'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (step == 1) _buildTypeStep(),
          if (step == 2) _buildDateTimeStep(),
          if (step == 3) _buildCaseTypeStep(),
          if (step == 4) _buildDescriptionStep(),
          const SizedBox(height: 24),
          Row(
            children: [
              if (step > 1)
                Expanded(
                  child: SecondaryButton(
                    text: 'السابق',
                    outlined: true,
                    onPressed: _previous,
                  ),
                ),
              if (step > 1) const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  text: step < 4
                      ? 'التالي'
                      : (submitting ? 'جاري الإرسال...' : 'إرسال الطلب'),
                  onPressed: submitting
                      ? null
                      : (!canContinue
                          ? _showValidationMessage
                          : (step < 4 ? _next : _submitRequest)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'إعادة تعيين',
                  outlined: true,
                  onPressed: _resetBooking,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  text: 'إلغاء',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? AppColors.background : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final int currentStep;

  const _StepCircle({
    required this.number,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentStep >= number;
    final completed = currentStep > number;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.secondary,
      ),
      child: Center(
        child: completed
            ? const Icon(
                Icons.check_circle,
                color: AppColors.background,
                size: 20,
              )
            : Text(
                '$number',
                style: TextStyle(
                  color: active ? AppColors.background : AppColors.foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.foreground.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}