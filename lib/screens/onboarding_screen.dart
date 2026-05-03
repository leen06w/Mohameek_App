import 'package:flutter/material.dart';

import '../app.dart';
import '../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

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
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_currentIndex];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
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
                                type: page.illustrationType,
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
                _PageIndicators(
                  currentIndex: _currentIndex,
                  count: _items.length,
                ),
                const SizedBox(height: 24),
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
                      item.buttonText,
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
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 22 : 10,
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
            'assets/images/image_screen1.png',
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
          'assets/images/image_screen2.png',
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
          'assets/images/image_screen3.png',
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

enum _IllustrationType {
  scale,
  search,
  security,
}