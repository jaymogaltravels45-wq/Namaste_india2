import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.navyGradient),
        child: Stack(
          children: [
            // Ambient glows
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.gold.withOpacity(0.18),
                    AppTheme.gold.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primary.withOpacity(0.3),
                    AppTheme.primary.withOpacity(0.0),
                  ]),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Entrance(
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: AppTheme.shadowGold,
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    AppTheme.gold.withOpacity(0.35),
                              ),
                            ),
                            child: const Text(
                              'BHARAT KA APNA CAB APP',
                              style: TextStyle(
                                color: AppTheme.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Entrance(
                      delayMs: 120,
                      child: Text(
                        AppConfig.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Entrance(
                      delayMs: 220,
                      child: Text(
                        'Transparent fare. Verified drivers.\nHar safar, premium feel.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Entrance(
                      delayMs: 320,
                      child: _point(
                          Icons.payments_rounded,
                          'Fixed outstation fares',
                          'No surge surprises, kabhi nahi'),
                    ),
                    Entrance(
                      delayMs: 400,
                      child: _point(
                          Icons.verified_user_rounded,
                          'KYC-verified drivers',
                          'Har driver police-verified'),
                    ),
                    Entrance(
                      delayMs: 480,
                      child: _point(Icons.sos_rounded, 'SOS + live safety',
                          'Trip share, emergency button'),
                    ),
                    Entrance(
                      delayMs: 560,
                      child: _point(Icons.currency_rupee_rounded,
                          'Cash ya UPI', 'Payment aapki marzi se'),
                    ),
                    const Spacer(),
                    Entrance(
                      delayMs: 660,
                      child: PremiumButton(
                        label: 'Get Started',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.go('/role'),
                        gradient: AppTheme.goldGradient,
                        shadows: AppTheme.shadowGold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Entrance(
                      delayMs: 740,
                      child: Center(
                        child: TextButton(
                          onPressed: () => context.go('/role'),
                          child: Text(
                            'I already have an account — Log in',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _point(IconData icon, String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Icon(icon, color: AppTheme.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
