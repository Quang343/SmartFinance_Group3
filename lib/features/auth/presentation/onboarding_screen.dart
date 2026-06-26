import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/scale_on_tap.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Chào Mừng Đến Với\nFinSmart',
      'image': 'assets/images/onboarding_coins.png',
      'buttonText': 'Tiếp tục',
    },
    {
      'title': 'Sẵn Sàng Làm Chủ\nTài Chính?',
      'image': 'assets/images/onboarding_phone.png',
      'buttonText': 'Bắt đầu',
    },
  ];

  void _onNextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Harmonious background colors
    final Color topBgColor = primaryColor;
    final Color bottomCardColor = isDark ? const Color(0xFF0C2C1F) : const Color(0xFFF5FAF6);
    final Color circleBgColor = isDark ? const Color(0xFF06150F) : const Color(0xFFE2F3EB);
    final Color textColorLight = const Color(0xFF0A231A);
    final Color textButtonColor = isDark ? Colors.white : const Color(0xFF0A231A);

    return Scaffold(
      backgroundColor: topBgColor,
      body: Stack(
        children: [
          // Page Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              final data = _onboardingData[index];
              return Column(
                children: [
                  // Top Title Area (approx 40% height)
                  Container(
                    height: size.height * 0.4,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data['title']!,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: textColorLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Card Area (approx 60% height)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: bottomCardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 3D Illustration Container
                          Container(
                            width: size.height * 0.28,
                            height: size.height * 0.28,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: circleBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                data['image']!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    index == 0
                                        ? Icons.account_balance_wallet
                                        : Icons.phonelink_setup,
                                    size: 80,
                                    color: primaryColor,
                                  );
                                },
                              ),
                            ),
                          ),

                          // Action Button
                          ScaleOnTap(
                            onTap: _onNextPage,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                data['buttonText']!,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: textButtonColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),

                          // Page Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _onboardingData.length,
                              (dotIndex) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == dotIndex
                                      ? primaryColor
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Skip Button at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: GestureDetector(
              onTap: () => context.go('/welcome'),
              child: Text(
                'Bỏ qua',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF0A231A).withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
