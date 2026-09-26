import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../core/routes/nav.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bg;
  late final AnimationController _content;
  late final Animation<double> _bgScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  int _currentSlide = 0;

  static const _slides = [
    _Slide(
      icon: Icons.flight_takeoff_rounded,
      title: 'Travel Across India',
      subtitle: 'Book outstation, local, and round trips with trusted drivers at fair fares.',
      accent: Color(0xFF1565C0),
    ),
    _Slide(
      icon: Icons.verified_user_rounded,
      title: '100% Safe & Verified',
      subtitle: 'All drivers are background-verified. Your safety is our top priority.',
      accent: Color(0xFF2E7D32),
    ),
    _Slide(
      icon: Icons.currency_rupee_rounded,
      title: 'Transparent Pricing',
      subtitle: 'No hidden charges. See the fare upfront before you book.',
      accent: Color(0xFFE65100),
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _bg = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
    _bgScale = Tween<double>(begin: 1.0, end: 1.08)
        .animate(CurvedAnimation(parent: _bg, curve: Curves.easeInOut));

    _content = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _content, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _content, curve: Curves.easeOutCubic));
    _content.forward();

    // Auto-advance slides
    Future.delayed(const Duration(seconds: 3), _nextSlide);
  }

  void _nextSlide() {
    if (!mounted) return;
    _content.reset();
    setState(() => _currentSlide = (_currentSlide + 1) % _slides.length);
    _content.forward();
    Future.delayed(const Duration(seconds: 3), _nextSlide);
  }

  @override
  void dispose() {
    _bg.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentSlide];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated gradient background
          AnimatedBuilder(
            animation: _bgScale,
            builder: (_, __) => Transform.scale(
              scale: _bgScale.value,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
              ),
            ),
          ),

          // ── Decorative blobs
          Positioned(
            right: -60,
            top: size.height * 0.05,
            child: _blob(220, Colors.white.withOpacity(0.07)),
          ),
          Positioned(
            left: -40,
            top: size.height * 0.25,
            child: _blob(160, AppTheme.gold.withOpacity(0.13)),
          ),
          Positioned(
            right: -20,
            bottom: size.height * 0.25,
            child: _blob(130, Colors.white.withOpacity(0.06)),
          ),

          // ── Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Entrance(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.directions_car_rounded,
                              color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Namaste India',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3)),
                            Text('Travel with trust',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Slide illustration
                  FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  slide.accent.withOpacity(0.25),
                                  Colors.white.withOpacity(0.12),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3), width: 2),
                            ),
                            child: Icon(slide.icon, size: 64, color: Colors.white),
                          ),
                          const SizedBox(height: 36),
                          Text(slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.15)),
                          const SizedBox(height: 16),
                          Text(slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 15,
                                  height: 1.6)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _currentSlide;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // ── CTA Buttons
                  Entrance(
                    delayMs: 300,
                    child: Column(
                      children: [
                        PremiumButton(
                          label: 'Get Started',
                          onPressed: () => Nav.push(context, '/role'),
                          icon: Icons.arrow_forward_rounded,
                          gradient: AppTheme.goldGradient,
                          shadows: AppTheme.shadowGold,
                          height: 58,
                        ),
                        const SizedBox(height: 14),
                        // Already have account
                        GestureDetector(
                          onTap: () =>
                              Nav.push(context, '/login', extra: {'role': 'customer'}),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account? ',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14)),
                                const Text('Sign In',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double s, Color c) =>
      Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _Slide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  const _Slide(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.accent});
}
