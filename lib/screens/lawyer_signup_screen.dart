import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/ui.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class LawyerSignUpScreen extends StatefulWidget {
  const LawyerSignUpScreen({super.key});

  @override
  State<LawyerSignUpScreen> createState() => _LawyerSignUpScreenState();
}

class _LawyerSignUpScreenState extends State<LawyerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _specializationController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _licenseDateController = TextEditingController();
  final _barAssociationController = TextEditingController();
  final _practiceAreasController = TextEditingController();
  final _streetController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController(text: 'المنطقة الشرقية');
  final _zipCodeController = TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender;
  LatLng _selectedLocation =
      const LatLng(26.4207, 50.0888); // إحداثيات الدمام كافتراضي

  // دالة الرزنامة
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _licenseDateController.text =
          "${picked.year}-${picked.month}-${picked.day}");
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار الجنس'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = AppUser(
        id: '',
        name: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(), // المنطقة
        address:
            '${_streetController.text.trim()}, ${_districtController.text.trim()}',
        role: 'lawyer',
        status: 'معلق',
        specialty: _specializationController.text.trim(),
        gender: _selectedGender!,
        licenseDate: _licenseDateController.text,
        barAssociation: _barAssociationController.text,
        practiceAreas: _practiceAreasController.text,
        zipCode: _zipCodeController.text,
      );

      // تم حذف كلمة password من هنا لأن الـ AuthService عندك يقبل user فقط
      final result =
          await _authService.signup(user, _passwordController.text.trim());
      if (!mounted) return;
      setState(() => _submitting = false);

      if (result.success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'فشل التسجيل')),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      debugPrint("Error: $e");
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم إرسال الطلب', textAlign: TextAlign.right),
        content: const Text('طلب انضمامك قيد المراجعة الآن من قبل الإدارة.',
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: const Text('موافق'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التسجيل كخبير قانوني')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('البيانات الشخصية'),
              _buildTextField(
                  'الاسم الكامل', _fullNameController, Icons.person),
              _buildTextField(
                  'البريد الإلكتروني', _emailController, Icons.email),
              _buildTextField('رقم الهاتف', _phoneController, Icons.phone),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: InputDecoration(
                    labelText: 'الجنس',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: ['ذكر', 'أنثى']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('المعلومات المهنية'),
              _buildTextField('التخصص', _specializationController, Icons.star),
              _buildTextField(
                  'رقم الترخيص', _licenseNumberController, Icons.badge),
              TextFormField(
                controller: _licenseDateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                    labelText: 'تاريخ الترخيص',
                    prefixIcon: Icon(Icons.calendar_month),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              _buildTextField('نقابة المحامين', _barAssociationController,
                  Icons.account_balance),
              _buildTextField(
                  'مجالات الممارسة', _practiceAreasController, Icons.gavel),
              _buildSectionTitle('تفاصيل الموقع'),
              _buildTextField('المنطقة', _cityController, Icons.map),
              _buildTextField('الحي', _districtController, Icons.location_city),
              _buildTextField('الشارع', _streetController, Icons.add_location),
              _buildTextField('الرمز البريدي', _zipCodeController, Icons.pin),
              const SizedBox(height: 10),
              const Text('اضغط على الخريطة لتحديد موقع المكتب',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 200,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                        initialCenter: _selectedLocation,
                        onTap: (_, p) => setState(() => _selectedLocation = p)),
                    children: [
                      TileLayer(
                        // تم تصحيح التكرار هنا
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                      ),
                      MarkerLayer(markers: [
                        Marker(
                            point: _selectedLocation,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40))
                      ]),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _copyLocationLink,
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ الرابط'),
                  ),
                  TextButton.icon(
                    onPressed: _openGoogleEarth,
                    icon: const Icon(Icons.public),
                    label: const Text('Google Earth'),
                  ),
                  TextButton.icon(
                    onPressed: _openGoogleMaps,
                    icon: const Icon(Icons.map),
                    label: const Text('Maps'),
                  ),
                ],
              ),
              _buildSectionTitle('الأمان'),
              _buildTextField('كلمة المرور', _passwordController, Icons.lock,
                  isPass: true,
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword)),
              _buildTextField('تأكيد كلمة المرور', _confirmPasswordController,
                  Icons.lock_clock,
                  isPass: true,
                  obscure: _obscureConfirmPassword,
                  onToggle: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword)),
              const SizedBox(height: 30),
              PrimaryButton(
                  text: _submitting ? 'جاري الإرسال...' : 'إرسال طلب التسجيل',
                  onPressed: _submitting ? null : _submit),
            ],
          ),
        ),
      ),
    );
  }

  // دالة لفتح الخرائط (Google Maps)
  Future<void> _openGoogleMaps() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_selectedLocation.latitude},${_selectedLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // دالة لفتح قوقل إيرث (Google Earth)
  Future<void> _openGoogleEarth() async {
    final url =
        'https://earth.google.com/web/@${_selectedLocation.latitude},${_selectedLocation.longitude},1000d';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  // دالة نسخ الرابط إلى الحافظة
  void _copyLocationLink() {
    'https://www.google.com/maps?q=${_selectedLocation.latitude},${_selectedLocation.longitude}';
    // يمكنك استخدام package:flutter/services.dart لنسخ الرابط
    // Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الموقع')),
    );
  }

  Widget _buildSectionTitle(String t) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(t,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)));

  Widget _buildTextField(String l, TextEditingController c, IconData i,
          {bool isPass = false,
          bool obscure = false,
          VoidCallback? onToggle}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: c,
          obscureText: isPass && obscure,
          decoration: InputDecoration(
            labelText: l,
            prefixIcon: Icon(i),
            suffixIcon: isPass
                ? IconButton(
                    icon:
                        Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: onToggle)
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => v!.isEmpty ? 'مطلوب' : null,
        ),
      );
}
