import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/lawyer.dart';
import '../services/location_service.dart';
import '../app.dart';

class SearchLawyersScreen extends StatefulWidget {
  const SearchLawyersScreen({super.key});

  @override
  State<SearchLawyersScreen> createState() => _SearchLawyersScreenState();
}

class _SearchLawyersScreenState extends State<SearchLawyersScreen> {
  final _controller = TextEditingController();
  final _locationService = LocationService();

  List<Lawyer> _lawyers = [];
  bool _loading = true;
  bool _locating = false;
  String selectedSpecialty = 'الكل';
  String selectedCity = 'الكل';
  bool showFilters = false;
  bool sortByNearest = false;
  UserLocationData? _currentLocation;

  List<String> get specialties {
    final dynamicList = _lawyers
        .map((e) => e.specialty)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    dynamicList.sort();
    return ['الكل', ...dynamicList];
  }

  List<String> get cities {
    final dynamicList =
        _lawyers.map((e) => e.city).where((e) => e.isNotEmpty).toSet().toList();
    dynamicList.sort();
    return ['الكل', ...dynamicList];
  }

  List<Lawyer> get filtered {
    final result = _lawyers.where((lawyer) {
      final query = _controller.text.trim().toLowerCase();

      // البحث بالاسم أو التخصص
      final matchesSearch = query.isEmpty ||
          lawyer.name.toLowerCase().contains(query) ||
          lawyer.specialty.toLowerCase().contains(query);

      // التصفية حسب التخصص (مع مراعاة القيم الافتراضية)
      final matchesSpecialty =
          selectedSpecialty == 'الكل' || lawyer.specialty == selectedSpecialty;

      // التصفية حسب المدينة
      final matchesCity = selectedCity == 'الكل' || lawyer.city == selectedCity;

      return matchesSearch && matchesSpecialty && matchesCity;
    }).toList();

    // الترتيب حسب الأقرب لموقعي
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
        return da.compareTo(db);
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLawyers() async {
    try {
      // جلب المستخدمين بصفة محامي فقط
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'lawyer')
          .get();

      if (!mounted) return;

      setState(() {
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

        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('حدث خطأ أثناء جلب البيانات: $e', success: false);
      }
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _currentLocation = location;
      sortByNearest = true;
      _locating = false;
    });

    _showMessage(
      location.isFallback
          ? 'تم استخدام موقع تقريبي لفرز النتائج'
          : 'تم تحديد موقعك بنجاح',
      success: !location.isFallback,
    );
  }

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
    final list = filtered; // القائمة المفلترة الجاهزة عندك

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
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(
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
                  itemCount: list.length + 1,
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
                          // استخدام دالة _actionChip اللي في صورتك
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

                    // 2. عرض كروت المحامين باستخدام الدوال المساعدة عندك
                    final lawyer = list[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () =>
                            _showLawyerActions(lawyer), // دالة الأكشن من صورتك
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
