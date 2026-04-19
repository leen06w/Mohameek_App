import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../models/lawyer.dart';
import '../services/lawyers_service.dart';
import '../services/location_service.dart';

class SearchLawyersScreen extends StatefulWidget {
  const SearchLawyersScreen({super.key});

  @override
  State<SearchLawyersScreen> createState() => _SearchLawyersScreenState();
}

class _SearchLawyersScreenState extends State<SearchLawyersScreen> {
  final _controller = TextEditingController();
  final _lawyersService = LawyersService();
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
    final dynamicList = _lawyers
        .map((e) => e.city)
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    dynamicList.sort();
    return ['الكل', ...dynamicList];
  }

  List<Lawyer> get filtered {
    final result = _lawyers.where((lawyer) {
      final query = _controller.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          lawyer.name.toLowerCase().contains(query) ||
          lawyer.specialty.toLowerCase().contains(query);
      final matchesSpecialty =
          selectedSpecialty == 'الكل' || lawyer.specialty == selectedSpecialty;
      final matchesCity = selectedCity == 'الكل' || lawyer.city == selectedCity;
      return matchesSearch && matchesSpecialty && matchesCity;
    }).toList();

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
    _loadLawyers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLawyers() async {
    final lawyers = await _lawyersService.fetchLawyers();
    if (!mounted) return;
    setState(() {
      _lawyers = lawyers;
      _loading = false;
    });
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
              const Center(child: SizedBox(width: 46, child: Divider(thickness: 4))),
              const SizedBox(height: 12),
              Text(
                lawyer.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
          color: active ? AppColors.primary.withValues(alpha: 0.08) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? AppColors.primary : AppColors.foreground),
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
    return AppShell(
      appBar: const AppHeader(title: 'البحث عن محامي', leadingIcon: Icons.arrow_back),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ابحث عن محامي أو تخصص...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'مسح',
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _actionChip(
                icon: Icons.filter_list,
                title: showFilters ? 'إخفاء التصفية' : 'تصفية النتائج',
                active: showFilters,
                onTap: () => setState(() => showFilters = !showFilters),
              ),
              _actionChip(
                icon: Icons.my_location,
                title: _locating ? 'جارٍ تحديد الموقع...' : 'الأقرب لموقعي',
                active: sortByNearest,
                onTap: _locating ? null : _detectLocation,
              ),
              _actionChip(
                icon: Icons.restart_alt,
                title: 'إعادة الضبط',
                onTap: _resetFilters,
              ),
            ],
          ),
          if (_currentLocation != null) ...[
            const SizedBox(height: 10),
            Text(
              _currentLocation!.label,
              style: TextStyle(
                color: _currentLocation!.isFallback ? Colors.orange.shade800 : AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (showFilters) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('التخصص', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .map((e) => Pill(
                              text: e,
                              active: selectedSpecialty == e,
                              onPressed: () => setState(() => selectedSpecialty = e),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('المدينة', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cities
                        .map((e) => Pill(
                              text: e,
                              active: selectedCity == e,
                              onPressed: () => setState(() => selectedCity = e),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '${filtered.length} محامي متاح',
            style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            SectionCard(
              child: Column(
                children: [
                  const EmptyState(icon: Icons.search_off, message: 'لا توجد نتائج مطابقة للبحث'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 170,
                    child: SecondaryButton(
                      text: 'إعادة ضبط الفلاتر',
                      outlined: true,
                      onPressed: _resetFilters,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((lawyer) {
              final distance = _distanceFor(lawyer);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showLawyerActions(lawyer),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  Text(lawyer.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(lawyer.specialty, style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.6))),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Color(0xFFA16207)),
                                      const SizedBox(width: 4),
                                      Text('${lawyer.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(width: 6),
                                      Text('(${lawyer.reviews} تقييم)', style: TextStyle(fontSize: 12, color: AppColors.foreground.withValues(alpha: 0.55))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showLawyerActions(lawyer),
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'خيارات',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: _miniStat('الخبرة', lawyer.experience)),
                            const SizedBox(width: 8),
                            Expanded(child: _miniStat('القضايا', '${lawyer.cases}')),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _miniStat(
                                distance == null ? 'المدينة' : 'يبعد عنك',
                                distance == null ? lawyer.city : '${distance.toStringAsFixed(1)} كم',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(lawyer.price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  const SizedBox(width: 4),
                                  Text('ر.س / استشارة', style: TextStyle(color: AppColors.foreground.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 110,
                              child: SecondaryButton(
                                text: 'الملف',
                                outlined: true,
                                onPressed: () => _openLawyerProfile(lawyer),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 132,
                              child: PrimaryButton(
                                text: 'حجز استشارة',
                                onPressed: () => _bookLawyer(lawyer),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
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
