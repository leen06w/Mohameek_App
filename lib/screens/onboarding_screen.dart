import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';

/// كلاس من نوع StatefulWidget يمثل الواجهة التعريفية الترحيبية الأولى التي تظهر للمستخدم عند فتح التطبيق لأول مرة.
/// يتولى الكلاس عرض مزايا المنصة الرئيسية بأسلوب انسيابي متحرك، وتهيئة المستخدم للانتقال لبوابة تسجيل الدخول.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

/// كلاس الحالة الديناميكي المسؤول عن إدارة حركة الصفحات [PageController]، ومراقبة الـ Index الحالي لتحديث النقاط السفلية ونصوص الأزرار.
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController(); // متحكم برمي للتنقل والتحكم بصفحات العرض التعريفية
  int _currentIndex =
      0; // متغير محلي لتتبع رقم الصفحة النشطة حالياً (يبدأ من 0 إلى 2)

// --- مصفوفة كائنات البيانات الثابتة للـ Onboarding متبعة مبدأ فصل البيانات عن الواجهات ---
  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.balance_rounded,
      title: 'محاميك',
      subtitle: 'في خدمتكم على مدار الساعة',
      description:
          'محامي متواجد لخدمتكم 24 ساعة\nفي جميع أنحاء المملكة بأسعار وباقات مناسبة',
      illustrationType: _IllustrationType.scale,
      buttonText: 'التالي',
    ),
    _OnboardingItem(
      icon: Icons.search_rounded,
      title: 'محامي متخصص في كافة المجالات القانونية',
      subtitle: '',
      description:
          'محامي متخصص في جميع التخصصات القانونية لتغطية\nكافة احتياجاتكم القانونية مع ضمان أعلى المستويات المهنية.',
      illustrationType: _IllustrationType.search,
      buttonText: 'التالي',
    ),
    _OnboardingItem(
      icon: Icons.shield_outlined,
      title: 'الخصوصية التامة',
      subtitle: '',
      description:
          'ضمان جودة المحامي مع الحفاظ على سرية وخصوصية\nمستندات القضية وبيانات العميل',
      illustrationType: _IllustrationType.security,
      buttonText: 'ابدأ الآن',
    ),
  ];

  @override
  void dispose() {
    _pageController
        .dispose(); // تفريغ الذاكرة من السيرفر والمتحكم فور الانتقال لمنع تسريب الذاكرة Memory Leaks
    super.dispose();
  }

  /// الدالة المسؤولة عن نقل المستخدم للصفحة التالية بـ أنيميشن ناعم، أو نقله لصفحة الدخول إذا كان في المحطة الأخيرة
  void _handleNext() {
    if (_currentIndex < _items.length - 1) {
      // نقل الكاميرا والصفحة للتالي بمنحنى حركة مريح للعين
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      // إتلاف الشاشة الترحيبية بالكامل والانتقال الجذري لبوابة الدخول دون إمكانية العودة للخلف (pushReplacementNamed)
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[
        _currentIndex]; // جلب كائن البيانات الفعلي بناءً على الصفحة الحالية المعروضة

    return Directionality(
      textDirection: TextDirection
          .rtl, // حقن اللغة والتوجيه العربي من اليمين لليسار لكافة عناصر الشاشة
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              children: [
                Expanded(
                  // بناء منشئ الصفحات الذكي والموفر للموارد (PageView.builder)
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex =
                            index; // تحديث المؤشر فور قيام العميل بسحب الشاشة بإصبعه
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _items[index];

                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          _TopIconBadge(icon: page.icon),
                          const SizedBox(height: 22),
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              height: 1.25,
                            ),
                          ),
                          if (page.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground.withValues(
                                  alpha: 0.65,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          Expanded(
                            child: Center(
                              child: _IllustrationCard(
                                type: page
                                    .illustrationType, // رسم الصورة والكرت المناسب ديناميكياً
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground.withValues(
                                  alpha: 0.68,
                                ),
                                height: 1.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
                // ويدجت رسم وتحديث النقاط الدائرية السفلية الذكية ومزامنتها محلياً
                _PageIndicators(
                  currentIndex: _currentIndex,
                  count: _items.length,
                ),
                const SizedBox(height: 24),
                // زر التقدم الأساسي العريض أسفل الواجهة
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      item.buttonText, // النص يتحدث تلقائياً (التالي -> ابدأ الآن)
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- الويدجتس المساعدة وبطاقات الرسوم البصرية لملف التهيئة ---
class _TopIconBadge extends StatelessWidget {
  final IconData icon;

  const _TopIconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 38,
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PageIndicators({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) {
          final active = index == currentIndex;
          // استخدام حاوية متحركة لتغيير عرض النقطة بشكل مطاطي ناعم وجميل ومحفز للـ UI
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active
                ? 22
                : 10, // النقطة النشطة تتمدد أفقياً لتأكيد الاختيار البصري للعميل
            height: 10,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final _IllustrationType type;

  const _IllustrationCard({required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      // توزيع كلاس الرسم المطلوب بناءً على نوع الـ Enum الممرر
      case _IllustrationType.scale:
        return const _ScaleIllustration();
      case _IllustrationType.search:
        return const _SearchIllustration();
      case _IllustrationType.security:
        return const _SecurityIllustration();
    }
  }
}

class _ScaleIllustration extends StatelessWidget {
  const _ScaleIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD4C9BE),
            width: 8,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Image.asset(
            'assets/images/image_screen1.png', // استدعاء ميزان العدالة من ملفات النظام
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SearchIllustration extends StatelessWidget {
  const _SearchIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 280,
        child: Image.asset(
          'assets/images/image_screen2.png', // استدعاء رسمة البحث عن الخبراء
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _SecurityIllustration extends StatelessWidget {
  const _SecurityIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 280,
        child: Image.asset(
          'assets/images/image_screen3.png', // استدعاء رسمة الحماية والتأمين المشفر
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final _IllustrationType illustrationType;
  final String buttonText;

  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustrationType,
    required this.buttonText,
  });
}

// تصنيف ترميزي مخصص (Enum) لتحديد الرسوم التوضيحية بأعلى درجات كفاءة واختصار الكود
enum _IllustrationType {
  scale,
  search,
  security,
}
