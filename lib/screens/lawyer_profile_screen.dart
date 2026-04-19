import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/location_links.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/ui.dart';
import '../data/mock_data.dart';
import '../models/lawyer.dart';
import '../services/location_service.dart';

class LawyerProfileScreen extends StatefulWidget {
  const LawyerProfileScreen({super.key});

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  int activeTab = 0;
  final Lawyer lawyer = MockData.lawyers.first;
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  UserLocationData? _userLocation;
  bool _locating = false;
  bool _isEditing = false;

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
    _nameController = TextEditingController(text: lawyer.name);
    _specialtyController = TextEditingController(text: lawyer.specialty);
    _emailController = TextEditingController(text: lawyer.email);
    _phoneController = TextEditingController(text: lawyer.phone);
    _bioController = TextEditingController(text: lawyer.bio);
    _officeNameController = TextEditingController(text: lawyer.officeName);
    _officeAddressController =
        TextEditingController(text: lawyer.officeAddress);
    _workHoursController = TextEditingController(text: lawyer.workHours);
    _priceController = TextEditingController(text: lawyer.price);
    _licenseNumberController =
        TextEditingController(text: lawyer.licenseNumber);
    _editableLocation = LatLng(lawyer.lat, lawyer.lng);
  }

  @override
  void dispose() {
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

  Future<void> _detectMyLocation() async {
    setState(() => _locating = true);
    final value = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _userLocation = value;
      _locating = false;
    });
  }

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

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  void _saveProfile() {
    setState(() => _isEditing = false);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('تم تحديث بيانات المحامي بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _onMapTap(TapPosition _, LatLng latLng) {
    if (!_isEditing) return;

    setState(() {
      _editableLocation = latLng;
    });

    _mapController.move(latLng, 15);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appBar: AppHeader(
        title: 'الملف الشخصي',
        leadingIcon: Icons.arrow_back,
        actions: [
          IconButton(
            onPressed: _isEditing ? _saveProfile : _toggleEdit,
            icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                                            lawyer.rating.toStringAsFixed(1),
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
                                      '(${lawyer.reviews} تقييم)',
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
                Row(
                  children: [
                    Expanded(
                      child: _statBox(
                        'الخبرة',
                        lawyer.experience,
                        Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'القضايا',
                        '${lawyer.cases}',
                        Icons.verified_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statBox(
                        'التقييم',
                        lawyer.rating.toStringAsFixed(1),
                        Icons.star_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          if (activeTab == 0) _buildInfoTab(),
          if (activeTab == 1) _buildMapTab(),
          if (activeTab == 2) _buildReviewsTab(),
        ],
      ),
    );
  }

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
                      label:
                          Text(_locating ? 'جارٍ تحديد موقعي...' : 'تحديد موقعي'),
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
                  Text('يبعد المكتب عنك تقريبًا ${distance.toStringAsFixed(1)} كم'),
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
                                    style: TextStyle(fontWeight: FontWeight.w700),
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