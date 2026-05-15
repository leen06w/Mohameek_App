import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // مكتبة الخرائط المفتوحة لتحديد موقع مكتب المحامي
import 'package:latlong2/latlong.dart'; // لتمثيل إحداثيات الموقع الجغرافي (خطوط الطول والعرض)
import '../core/theme/app_colors.dart';
import '../core/utils/location_links.dart'; // روابط المساعد الخارجي لخرائط جوجل وإيرث
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../services/location_service.dart'; // خدمة تحديد المواقع الجغرافية وحساب المسافات
import 'package:cloud_firestore/cloud_firestore.dart'; // مكتبة الفايربيس الأساسية لتحديث بيانات الملف الشخصي
import '../models/app_user.dart';
import '../services/auth_service.dart';

/// كلاس من نوع StatefulWidget يدير واجهة "الملف الشخصي والمهني للمحامي".
/// يدمج بذكاء تصفحاً ثلاثياً تبويبياً (المعلومات، الموقع الجغرافي، التقييمات) داخل بيئة واحدة [activeTab]،
/// ويدعم التحول الديناميكي بين وضعيتين: وضع العرض الآمن، ووضع التعديل والحفظ المباشر في الـ Firestore.
class LawyerProfileScreen extends StatefulWidget {
  const LawyerProfileScreen({super.key});

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  int activeTab =
      0; // التحكم بالتبويب النشط حالياً (0: المعلومات، 1: الموقع، 2: التقييمات)
  final AuthService _authService = AuthService();
  AppUser? user;
  final LocationService _locationService = LocationService();
  final MapController _mapController =
      MapController(); // متحكم خاص لإعادة توجيه وتحريك الخريطة برمجياً

  // تعريف متأخر للكنترولرز لضمان تهيئتها النظيفة داخل initState
  late final TextEditingController _experienceController;
  late final TextEditingController _casesCountController;

  UserLocationData?
      _userLocation; // لحفظ بيانات الموقع الحالي للمستخدم عند النقر على "تحديد موقعي"
  bool _locating = false; // مؤشر تتبع حالة جلب موقع الجوال الحالي
  bool _isEditing =
      false; // متغير للتحكم بوضعية الشاشة (true: وضع التعديل، false: وضع العرض فقط)

  late final TextEditingController _nameController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _officeNameController;
  late final TextEditingController _officeAddressController;
  late final TextEditingController _workHoursController;
  late final TextEditingController _priceController;
  late final TextEditingController _licenseNumberController;

  late LatLng _editableLocation;
  @override
  void initState() {
    super.initState();
    _editableLocation =
        const LatLng(26.4207, 50.0888); // إحداثيات افتراضية أولية لموقع المكتب

// إعداد القيم الافتراضية للكنترولرز لتفادي ظهور حقول فارغة في حال تعطل خادم قاعدة البيانات
    _nameController = TextEditingController(text: "نورة العتيبي");
    _specialtyController =
        TextEditingController(text: "قانون الأحوال الشخصية والعمالية");
    _experienceController = TextEditingController(text: "7");
    _casesCountController = TextEditingController(text: "89");
    _bioController = TextEditingController(
        text:
            "محامية ممارسة متخصصة في الأنظمة العمالية وقضايا الأحوال الشخصية، بخبرة تمتد لـ 7 سنوات.");
    _emailController = TextEditingController(text: "lawyer@test.com");
    _phoneController = TextEditingController(text: "0551122334");

    // الكنترولرز المتبقية
    _officeNameController =
        TextEditingController(text: "مكتب نورة للمحاماة والاستشارات");
    _officeAddressController =
        TextEditingController(text: "طريق الملك فهد، حي الملقا، الرياض 12211");
    _workHoursController =
        TextEditingController(text: "الأحد - الخميس | 9:00 ص - 5:00 م");
    _priceController = TextEditingController(text: "350 SAR");
    _licenseNumberController = TextEditingController(text: "L-2025-442");

    // ملاحظة: عطلنا استدعاء الفايربيس هنا مؤقتاً لتجنب التعليق (ANR)
    // _loadCurrentLawyerData();
  }

// دالة جلب بيانات المحامي الحالي من الفايربيس وحقنها داخل الحقول ديناميكياً
  Future<void> _loadCurrentLawyerData() async {
    final u = await _authService.getCurrentUser();
    final String docId = u?.id ?? 'lawyer_456';
    // التأكد من وجود الـ ID لمنع الانهيار
    if (docId.isNotEmpty) {
      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(docId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          // 1. جلب وتحديث البيانات العلوية والإحصائية
          _nameController.text = 'نورة العتيبي';
          _experienceController.text = '7 سنوات';
          _casesCountController.text = data['casesCount'] ?? '89';

          // 2. النبذة ومعلومات الاتصال
          _bioController.text = data['bio'] ?? ''; // ربط النبذة (bio)[cite: 2]
          _emailController.text =
              data['email'] ?? ''; // البريد الإلكتروني[cite: 2]
          _phoneController.text = data['phone'] ?? ''; // رقم الجوال[cite: 2]

          // 3. معلومات تفاصيل المكتب الجغرافية والإدارية
          _officeNameController.text = "مكتب نورة للمحاماة والاستشارات";
          _officeAddressController.text =
              "طريق الملك فهد، حي الملقا، الرياض 12211";
          _workHoursController.text = "الأحد - الخميس | 9:00 ص - 5:00 م";

          // 4. ربط التخصص وأسعار الاستشارات
          _specialtyController.text =
              data['lawyerSpecialty'] ?? data['specialty'] ?? '';
          _priceController.text = data['price'] ?? '350 SAR';
        });
      }
    }
  }

  @override
  void dispose() {
    // إغلاق وتفريغ الذاكرة من كافة الكنترولرز فور الخروج من الواجهة لمنع تعليق ومشاكل الذاكرة
    _nameController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _officeNameController.dispose();
    _officeAddressController.dispose();
    _workHoursController.dispose();
    _priceController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  // دالة تتبع وجلب إحداثيات موقع جوال المحامي الحالي لتسهيل حساب المسافات
  Future<void> _detectMyLocation() async {
    setState(() => _locating = true);
    final value = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = value;
      _locating = false;
    });
  }

// دالة (Getter) لحساب المسافة الجغرافية بالكيلومترات بين المحامي ومكتبه ديناميكياً
  double? get _distanceKm {
    final loc = _userLocation;
    if (loc == null) return null;
    return _locationService.distanceKm(
      fromLat: loc.latitude,
      fromLng: loc.longitude,
      toLat: _editableLocation.latitude,
      toLng: _editableLocation.longitude,
    );
  }

// دالة حفظ وحقن البيانات المحدثة داخل مستند المحامي بـ مجموع الـ Users في الفايربيس
  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfile() async {
    final u = await _authService.getCurrentUser();
    if (!mounted) return;

    // تحديث البيانات في Firestore
    await FirebaseFirestore.instance.collection('Users').doc(u?.id).update({
      'name': _nameController.text,
      'specialty': _specialtyController.text,
      'phone': _phoneController.text,
      'bio': _bioController.text,
      'officeName': _officeNameController.text,
      'latitude': _editableLocation.latitude, // حفظ خط العرض المحدث من الخريطة
      'longitude':
          _editableLocation.longitude, // حفظ خط الطول المحدث من الخريطة
    });

    setState(
        () => _isEditing = false); // إعادة الشاشة لوضعية العرض الآمنة بعد الحفظ

    // إظهار رسالة النجاح
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات بنجاح')),
      );
    }
  }

// دالة التفاعل مع الخريطة؛ تسمح للمحامي بتغيير مكان مكتبه بنقرة ماوس واحدة أثناء وضع التعديل
  void _onMapTap(TapPosition _, LatLng latLng) {
    if (!_isEditing) return;

    setState(() {
      _editableLocation = latLng; // تحديث الإحداثيات محلياً فور النقر
    });

    _mapController.move(latLng,
        15); // نقل عين الكاميرا في الخريطة للنقطة الجديدة مع مستوى زووم 15
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppHeader(
        title: 'الملف الشخصي',
        leadingIcon: Icons.arrow_back,
        actions: [
          // زر علوي ذكي يتغير شكله ودالته تلقائياً؛ يُظهر "صح" للحفظ عند التعديل، ويُظهر "قلم" للبدء عند العرض
          IconButton(
            onPressed: _isEditing ? _saveProfile : _toggleEdit,
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الكرت العلوي الأساسي لعرض الصورة والاسم والتخصص ونسب التقييم الإجمالية
          SectionCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 42,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _isEditing
                          ? Column(
                              // واجهة حقول الإدخال عند تفعيل وضع التعديل
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'اسم المحامي',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _specialtyController,
                                  decoration: const InputDecoration(
                                    hintText: 'التخصص',
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              // واجهة النصوص الثابتة المحمية عند وضع العرض
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _specialtyController.text,
                                  style: TextStyle(
                                    color: AppColors.foreground.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Color(0xFFA16207),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            4.5.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFFA16207),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${10} تقييم)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.foreground.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // صف مربعات الإحصائيات المصغرة (الخبرة، القضايا، التقييم السريع)
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        'الخبرة', // 1. العنوان (Label)
                        '${_experienceController.text} سنوات', // 2. القيمة (Value)
                        Icons.work_history_rounded, // 3. الأيقونة (Icon)
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'القضايا', // 1. العنوان
                        _casesCountController.text, // 2. القيمة
                        Icons.gavel_rounded, // 3. الأيقونة
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'التقييم', // 1. العنوان
                        '4.8', // 2. القيمة
                        Icons.star_outline, // 3. الأيقونة
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // أزرار شريط التصفح السفلي (Pills) للتنقل المرن بين أقسام الملف
          Row(
            children: [
              Expanded(
                child: Pill(
                  text: 'المعلومات',
                  active: activeTab == 0,
                  onPressed: () => setState(() => activeTab = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Pill(
                  text: 'الموقع',
                  active: activeTab == 1,
                  onPressed: () => setState(() => activeTab = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Pill(
                  text: 'التقييمات',
                  active: activeTab == 2,
                  onPressed: () => setState(() => activeTab = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // عرض القسم المطلوب بناءً على قيمة التبويب المختار محلياً حالياً
          if (activeTab == 0) _buildInfoTab(),
          if (activeTab == 1) _buildMapTab(),
          if (activeTab == 2) _buildReviewsTab(),
        ],
      ),
    );
  }

// --- بناء التبويب الأول: المعلومات والأسعار والترخيص ---
  Widget _buildInfoTab() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تعديل المعلومات الأساسية',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الجوال',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(
                    labelText: 'رقم الترخيص',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سعر الاستشارة',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'نبذة عن المحامي',
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نبذة',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                _bioController.text,
                style: TextStyle(
                  color: AppColors.foreground.withValues(alpha: 0.68),
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'معلومات الاتصال',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _infoTile(
                Icons.mail_outline,
                'البريد الإلكتروني',
                _emailController.text,
                ltr: true,
              ),
              const SizedBox(height: 12),
              _infoTile(
                Icons.phone_outlined,
                'رقم الجوال',
                _phoneController.text,
                ltr: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_outlined),
                  SizedBox(width: 6),
                  Text(
                    'أسعار الاستشارات',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _priceRow('استشارة عن بعد', '${_priceController.text} ر.س'),
              const SizedBox(height: 8),
              _priceRow(
                'استشارة هاتفية',
                '${(int.tryParse(_priceController.text) ?? 500) - 100} ر.س',
              ),
              const SizedBox(height: 8),
              _priceRow(
                'استشارة حضورية',
                '${(int.tryParse(_priceController.text) ?? 500) + 100} ر.س',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'رقم الترخيص',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _licenseNumberController.text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

// --- بناء التبويب الثاني: الخريطة الجغرافية ومعلومات عنوان مكتب المحاماة ---
  Widget _buildMapTab() {
    final distance = _distanceKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'معلومات المكتب',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (_isEditing) ...[
                TextField(
                  controller: _officeNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المكتب',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _officeAddressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'عنوان المكتب',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _workHoursController,
                  decoration: const InputDecoration(
                    labelText: 'ساعات العمل',
                  ),
                ),
              ] else ...[
                Text(
                  _officeNameController.text,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_officeAddressController.text)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_workHoursController.text)),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _locating ? null : _detectMyLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                          _locating ? 'جارٍ تحديد موقعي...' : 'تحديد موقعي'),
                    ),
                  ),
                ],
              ),
              if (_userLocation != null) ...[
                const SizedBox(height: 10),
                Text(
                  _userLocation!.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _userLocation!.isFallback
                        ? Colors.orange.shade800
                        : AppColors.primary,
                  ),
                ),
                if (distance != null) ...[
                  const SizedBox(height: 6),
                  Text(
                      'يبعد المكتب عنك تقريبًا ${distance.toStringAsFixed(1)} كم'),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'تعديل موقع المكتب' : 'الموقع على الخريطة',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _editableLocation,
                    initialZoom: 14,
                    onTap: _onMapTap,
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
                          point: _editableLocation,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                        if (_userLocation != null)
                          Marker(
                            point: LatLng(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                            ),
                            width: 38,
                            height: 38,
                            child: const Icon(
                              Icons.my_location,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      _isEditing
                          ? 'اضغط على الخريطة لتحديث موقع المكتب'
                          : 'إحداثيات موقع المكتب الحالية',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${_editableLocation.latitude.toStringAsFixed(6)}  |  Lng: ${_editableLocation.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'نسخ الرابط',
                      outlined: true,
                      onPressed: () {
                        LocationLinks.copyMapsLink(
                          context,
                          lat: _editableLocation.latitude,
                          lng: _editableLocation.longitude,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      text: 'Google Earth',
                      onPressed: () {
                        LocationLinks.openEarth(
                          context,
                          lat: _editableLocation.latitude,
                          lng: _editableLocation.longitude,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                text: 'فتح في خرائط Google',
                icon: const Icon(Icons.location_on_outlined),
                onPressed: () {
                  LocationLinks.openMaps(
                    context,
                    lat: _editableLocation.latitude,
                    lng: _editableLocation.longitude,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

// --- بناء التبويب الثالث: سجل المراجعات وتقييمات الطلاب والعملاء السابقة للمحامي ---
  Widget _buildReviewsTab() {
    const reviews = [
      (
        'عميل 1',
        'منذ أسبوعين',
        'تجربة ممتازة، محامي محترف وملم بجميع جوانب القضية. أنصح بالتعامل معه.'
      ),
      (
        'عميل 2',
        'منذ شهر',
        'شرح واضح ومتابعة دقيقة، وتم توضيح الخيارات القانونية بشكل سهل.'
      ),
      ('عميل 3', 'منذ شهرين', 'تعامل احترافي وسرعة في الرد والاستشارة.'),
    ];

    return Column(
      children: reviews
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Color(0xFFA16207),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.9',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  AppColors.foreground.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(item.$3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

// ويدجت بناء مربعات الإحصاءات الثلاثية (الخبرة والقضايا والتقييم)
  Widget _statBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foreground.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

// بناء أسطر التبويب الفرعية لمعلومات البريد والجوال مع التحكم بالتوجيه
  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    bool ltr = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.foreground.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              ),
            ],
          ),
        ),
      ],
    );
  }

// بناء أسطر أسعار قنوات تقديم الاستشارة المتنوعة
  Widget _priceRow(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
