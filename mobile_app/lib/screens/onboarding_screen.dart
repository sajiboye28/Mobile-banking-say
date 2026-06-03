import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_banking/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Screen — shown only on first launch
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Per-page gradient colors: blue → purple → green
  static const List<List<Color>> _pageGradients = [
    [Color(0xFF0052FF), Color(0xFF2A6EFF)],   // blue
    [Color(0xFF6B21A8), Color(0xFF9333EA)],   // purple
    [Color(0xFF047857), Color(0xFF10B981)],   // green
  ];

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.account_balance_rounded,
      headline: 'Banking Made Simple',
      subtext:
          'Manage your money, send transfers, and track spending — all in one place.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      headline: 'Bank-Grade Security',
      subtext:
          'Your funds are protected with biometric authentication, TCC codes, and real-time transaction alerts.',
    ),
    _OnboardingPage(
      icon: Icons.bolt_rounded,
      headline: 'Instant Transfers',
      subtext:
          'Send money to anyone instantly using their email or account number. Zero fees, always.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    widget.onComplete?.call();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final gradColors = _pageGradients[_currentPage];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gradColors[0].withOpacity(0.18),
            AppColors.background,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar (Skip) ──────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedOpacity(
                      opacity: isLast ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: TextButton(
                        onPressed: isLast ? null : _complete,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant.withOpacity(0.7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── PageView ────────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingPageView(
                      page: _pages[index],
                      gradientColors: _pageGradients[index],
                    );
                  },
                ),
              ),

              // ── Dots indicator ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == i
                            ? AppColors.primaryContainer
                            : AppColors.onSurfaceVariant.withOpacity(0.25),
                      ),
                    ),
                  ),
                ),
              ),

              // ── CTA Button ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLast
                            ? [const Color(0xFF047857), const Color(0xFF10B981)]
                            : [AppColors.primaryContainer, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (isLast
                                  ? const Color(0xFF10B981)
                                  : AppColors.primaryContainer)
                              .withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model for a single onboarding page
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage {
  final IconData icon;
  final String headline;
  final String subtext;

  const _OnboardingPage({
    required this.icon,
    required this.headline,
    required this.subtext,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Single page content widget
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;
  final List<Color> gradientColors;

  const _OnboardingPageView({
    required this.page,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon in gradient container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 72,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 48),

          // Headline
          Text(
            page.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 16),

          // Subtext
          Text(
            page.subtext,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.onSurfaceVariant.withOpacity(0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
