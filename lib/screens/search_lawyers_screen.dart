import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/lawyer.dart'; // موديل بيانات المحامي المعتمد بالنظام
import '../services/location_service.dart'; // خدمة جلب الإحداثيات الحية لحساب وفرز المسافات
import '../app.dart';

/// كلاس من نوع StatefulWidget يمثل شاشة "البحث عن محامي" الموجهة للطلاب.
/// يتولى الكلاس جلب الخبراء القانونيين من الـ Firestore، وإدارة فلاتر التخصصات والمدن، والفرز الجغرافي حسب الأقرب لموقع الطالب.
class SearchLawyersScreen extends StatefulWidget {
  const SearchLawyersScreen({super.key});

  @override
  State<SearchLawyersScreen> createState() => _SearchLawyersScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن معالجة نصوص الاستعلام، وعمليات المقارنة الجغرافية، ورسم كروت المحامين وقوائم التصفية.
class _SearchLawyersScreenState extends State<SearchLawyersScreen> {
  final _controller =
      TextEditingController(); // متحكم بحقل البحث النصي لمراقبة المدخلات فوراً
  final _locationService = LocationService(); // تهيئة خدمة المواقع الجغرافية

  List<Lawyer> _lawyers =
      []; // القائمة الكلية للمحامين المسترجعة من قاعدة البيانات
  bool _loading =
      true; // مؤشر تتبع حالة جلب البيانات لإظهار حلقة التحميل العلوية
  bool _locating = false; // تتبع حالة استدعاء الـ GPS للجوال حالياً
  String selectedSpecialty =
      'الكل'; // التخصص المختار حالياً للتصفية (الافتراضي: الكل)
  String selectedCity = 'الكل'; // المدينة المختارة حالياً للتصفية
  bool showFilters = false; // التحكم بظهور وإخفاء شريط الفلاتر المنسدل
  bool sortByNearest = false; // متغير منطقي لتفعيل الفرز الجغرافي حسب الأقرب
  UserLocationData?
      _currentLocation; // لحفظ بيانات خطوط الطول والعرض الخاصة بالطالب الحالي

  /// مستخرج ديناميكي (Getter) يقرأ تخصصات المحامين المتاحة، ويصفي التكرارات منها لإنشاء قائمة فلاتر فريدة وممررة
  List<String> get specialties {
    final dynamicList = _lawyers
        .map((e) => e.specialty)
        .where((e) => e.isNotEmpty)
        .toSet() // تحويل لمجموعة (Set) لحذف التكرارات تلقائياً
        .toList();
    dynamicList.sort(); // ترتيب التخصصات أبجدياً
    return ['الكل', ...dynamicList];
  }

  /// مستخرج ديناميكي (Getter) لتجميع قائمة المدن الفريدة والمسجلة للمحامين بداخل السيرفر آلياً
  List<String> get cities {
    final dynamicList =
        _lawyers.map((e) => e.city).where((e) => e.isNotEmpty).toSet().toList();
    dynamicList.sort();
    return ['الكل', ...dynamicList];
  }

  /// المحرك الأساسي للشاشة (Filter Core Logic): مستخرج يقوم بمعالجة مصفوفة المحامين وتطبيق شروط الفرز المركبة لحظياً
  List<Lawyer> get filtered {
    final result = _lawyers.where((lawyer) {
      final query = _controller.text.trim().toLowerCase();

      // 1. شرط البحث النصي: مطابقة استعلام الطالب مع اسم المحامي أو تخصصه المهني
      final matchesSearch = query.isEmpty ||
          lawyer.name.toLowerCase().contains(query) ||
          lawyer.specialty.toLowerCase().contains(query);

      // 2. شرط التصفية حسب التخصص
      final matchesSpecialty =
          selectedSpecialty == 'الكل' || lawyer.specialty == selectedSpecialty;

      // 3. شرط التصفية حسب المدينة المسجلة
      final matchesCity = selectedCity == 'الكل' || lawyer.city == selectedCity;

      return matchesSearch &&
          matchesSpecialty &&
          matchesCity; // دمج الشروط الثلاثة معاً
    }).toList();

    // 4. خوارزمية الترتيب الجغرافي: إذا تم تفعيل فرز الأقرب وتوفرت إحداثيات الطالب، يتم فرز المصفوفة تصاعدياً
    if (sortByNearest && _currentLocation != null) {
      result.sort((a, b) {
        final da = _locationService.distanceKm(
          fromLat: _currentLocation!.latitude,
          fromLng: _currentLocation!.longitude,
          toLat: a.lat,
          toLng: a.lng,
        );
        final db = _locationService.distanceKm(
          fromLat: _currentLocation!.latitude,
          fromLng: _currentLocation!.longitude,
          toLat: b.lat,
          toLng: b.lng,
        );
        return da.compareTo(db); // مقارنة وفصل المسافات الأقرب فالأبعد
      });
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadLawyers(); // تحميل البيانات عند فتح الشاشة

    // تأخير بسيط لضمان سلاسة فتح الواجهة قبل أي عمليات أخرى
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // يمكنك تفعيل تحديد الموقع التلقائي هنا لاحقاً إذا رغبتِ
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // إغلاق الكنترولر لحماية الذاكرة ومنع تسريب البيانات
    super.dispose();
  }

  /// دالة جلب البيانات غير المتزامنة؛ تتصل بمجموعة Users وتسترجع فقط المستخدمين بصفة lawyer
  Future<void> _loadLawyers() async {
    try {
      // جلب المستخدمين بصفة محامي فقط
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .get();

      if (!mounted) return;

      setState(() {
        // تحويل المستندات المسترجعة من الفايربيس إلى كائنات ممررة داخل موديل الـ Lawyer
        _lawyers = snapshot.docs.map((doc) {
          final data = doc.data();
          // ننشئ الكائن يدوياً لتمرير الحقول المطلوبة (Required) وحمايته من الأخطاء
          return Lawyer(
            id: doc.id,
            name: data['name'] ?? 'محامي غير مسمى',
            email: data['email'] ?? '',
            phone: data['phone'] ?? '',
            city: data['city'] ?? 'غير محددة',
            specialty: data['specialty'] ?? 'قانون عام',
            experience: data['experience'] ?? '0 سنوات',
            casesCount: data['casesCount']?.toString() ?? '0',
            rating: (data['rating'] ?? 0.0).toDouble(),
            reviews: data['reviews'] ?? 0,
            cases: data['cases'] ?? 0,
            price: (data['price'] ?? 0).toString(),
            lat: (data['lat'] ?? 26.4207).toDouble(),
            lng: (data['lng'] ?? 50.0888).toDouble(),
            // تمرير الحقول الإلزامية الجديدة بقيم افتراضية[cite: 6]
            officeName: data['officeName'] ?? 'مكتب محاماة',
            officeAddress: data['officeAddress'] ?? 'العنوان غير محدد',
            workHours: data['workHours'] ?? '9:00 ص - 5:00 م',
          );
        }).toList();

        _loading = false; // إيقاف حلقة التحميل بعد اكتمال البيانات
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('حدث خطأ أثناء جلب البيانات: $e', success: false);
      }
    }
  }

  /// دالة استدعاء مستشعر الـ GPS لتحديد موقع الطالب وتفعيل الفرز الكيلومتري للأقرب
  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
      sortByNearest = true; // تشغيل مفتاح الفرز الجغرافي
      _locating = false;
    });

    _showMessage(
      location.isFallback
          ? 'تم استخدام موقع تقريبي لفرز النتائج'
          : 'تم تحديد موقعك بنجاح',
      success: !location.isFallback,
    );
  }

  /// تصفير كافة المدخلات وإعادة تعيين حالات التصفية للوضع الافتراضي النظيف
  void _resetFilters() {
    setState(() {
      _controller.clear();
      selectedSpecialty = 'الكل';
      selectedCity = 'الكل';
      showFilters = false;
      sortByNearest = false;
    });
    _showMessage('تمت إعادة ضبط الفلاتر');
  }

  /// دالة مساعدة لحساب المسافة الفاصلة بين موقع الطالب والمحامي الحالي المختار
  double? _distanceFor(Lawyer lawyer) {
    final loc = _currentLocation;
    if (loc == null) return null;
    return _locationService.distanceKm(
      fromLat: loc.latitude,
      fromLng: loc.longitude,
      toLat: lawyer.lat,
      toLng: lawyer.lng,
    );
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

  void _openLawyerProfile(Lawyer lawyer) {
    Navigator.pushNamed(
      context,
      AppRoutes.lawyerProfile,
      arguments: lawyer,
    );
  }

  void _bookLawyer(Lawyer lawyer) {
    Navigator.pushNamed(
      context,
      AppRoutes.userBooking,
      arguments: lawyer,
    );
  }

  /// فتح لوحة الخيارات السفلية المنبثقة (BottomSheet) لعرض ملخص سريع لبيانات المحامي قبل الحجز
  void _showLawyerActions(Lawyer lawyer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final distance = _distanceFor(lawyer);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                  child: SizedBox(width: 46, child: Divider(thickness: 4))),
              const SizedBox(height: 12),
              Text(
                lawyer.name,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                lawyer.specialty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.foreground.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _InfoRow(label: 'المدينة', value: lawyer.city),
              _InfoRow(label: 'الخبرة', value: lawyer.experience),
              _InfoRow(label: 'القضايا', value: '${lawyer.cases}'),
              _InfoRow(
                label: distance == null ? 'السعر' : 'يبعد عنك',
                value: distance == null
                    ? '${lawyer.price} ر.س'
                    : '${distance.toStringAsFixed(1)} كم',
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                text: 'حجز استشارة',
                onPressed: () {
                  Navigator.pop(context);
                  _bookLawyer(lawyer);
                },
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                text: 'عرض الملف الشخصي',
                outlined: true,
                onPressed: () {
                  Navigator.pop(context);
                  _openLawyerProfile(lawyer);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// مكون مربع الإحصائيات الصغير (الخبرة، القضايا، المدينة) المرسوم بداخل الكرت الأساسي
  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.foreground.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  /// بطاقات التحكم العلوية (Chips) المسؤولة عن تبديل حالات التصفية وتفعيل الـ GPS
  Widget _actionChip({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.primary : AppColors.foreground),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primary : AppColors.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered; // القائمة المفلترة الجاهزة للعرض

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('البحث عن محامي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D2D4D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator()) // عرض حلقة التحميل أثناء جلب البيانات من الفايربيس
          : list.isEmpty
              ? Center(
                  // واجهة خلو النتائج في حال لم يتطابق البحث مع أي محامي
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('لا يوجد محامين متاحين حالياً'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _resetFilters, // دالة إعادة الضبط من صورتك
                        child: const Text('إعادة ضبط الفلاتر'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: list.length +
                      1, // إضافة 1 لبناء شريط البحث كعنصر علوي ثابت داخل السكرول
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // 1. قسم البحث والفلاتر في أعلى القائمة
                      return Column(
                        children: [
                          TextField(
                            controller: _controller,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'ابحث عن محامي...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _actionChip(
                                  icon: Icons.filter_list,
                                  title: showFilters
                                      ? 'إخفاء التصفية'
                                      : 'تصفية النتائج',
                                  active: showFilters,
                                  onTap: () => setState(
                                      () => showFilters = !showFilters),
                                ),
                                const SizedBox(width: 8),
                                _actionChip(
                                  icon: Icons.my_location,
                                  title: 'الأقرب لموقعي',
                                  active: sortByNearest,
                                  onTap:
                                      _detectLocation, // دالة الموقع من صورتك
                                ),
                                const SizedBox(width: 8),
                                _actionChip(
                                  icon: Icons.restart_alt,
                                  title: 'إعادة الضبط',
                                  onTap: _resetFilters, // دالة الضبط من صورتك
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    // 2. عرض كروت المحامين باستخدام الدوال المساعدة
                    final lawyer = list[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showLawyerActions(lawyer),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.person)),
                                  title: Text(lawyer.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(lawyer.specialty),
                                  trailing: Text('${lawyer.price} ر.س',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ),
                                const SizedBox(height: 8),
                                // استخدام دالة _miniStat اللي في صورتك
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _miniStat('الخبرة', lawyer.experience),
                                    _miniStat(
                                        'القضايا',
                                        (lawyer as dynamic)
                                                .casesCount
                                                ?.toString() ??
                                            '145'),
                                    _miniStat('المدينة', lawyer.city),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // دالة بناء الكرت المبسطة لضمان عدم حدوث Overflow
  Widget _simpleLawyerCard(Lawyer lawyer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFF1A237E),
                  child: Icon(Icons.person, color: Colors.white)),
              title: Text(lawyer.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(lawyer.specialty),
              trailing: Text('${lawyer.price} ر.س',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => _openLawyerProfile(lawyer),
                    child: const Text('المزيد')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _bookLawyer(lawyer),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E)),
                  child: const Text('حجز استشارة',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// ويدجت مساعدة من نوع StatelessWidget مخصصة لتنسيق أسطر كرت التفاصيل السفلي [BottomSheet].
/// تعرض التسمية والقيمة المقابلة لها بمحاذاة منسقة تدعم جمالية واجهة الاستخدام بالتطبيق.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

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
