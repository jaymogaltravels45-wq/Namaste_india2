import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../core/routes/nav.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.shadowSm,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppTheme.textPrimary),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Entrance(
                child: Text(
                  'Aap kaun hain?',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              Entrance(
                delayMs: 80,
                child: Text(
                  'Apna role chunein — usi hisaab se login hoga.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 30),
              Entrance(
                delayMs: 160,
                child: _roleCard(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Customer',
                  subtitle: 'Ride book karo — one-way, round trip, local ya apni bid',
                  gradient: AppTheme.blueGradient,
                  shadow: AppTheme.shadowBlue,
                  onTap: () =>
                      Nav.push(context, '/login', extra: {'role': 'customer'}),
                ),
              ),
              const SizedBox(height: 14),
              Entrance(
                delayMs: 240,
                child: _roleCard(
                  context,
                  icon: Icons.drive_eta_rounded,
                  title: 'Driver',
                  subtitle: 'Trip leke kamao — apne time pe, apne rate pe',
                  gradient: AppTheme.successGradient,
                  shadow: [
                    BoxShadow(
                      color: AppTheme.success.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  onTap: () =>
                      Nav.push(context, '/login', extra: {'role': 'driver'}),
                ),
              ),
              const SizedBox(height: 14),
              Entrance(
                delayMs: 320,
                child: _roleCard(
                  context,
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin',
                  subtitle: 'Platform manage karo — bookings, drivers, fares',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF57C00), Color(0xFFE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadow: [
                    BoxShadow(
                      color: const Color(0xFFF57C00).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  onTap: () => Nav.push(context, '/admin'),
                ),
              ),
              const Spacer(),
              Entrance(
                delayMs: 400,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppTheme.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        '100% secure · OTP verified login',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required List<BoxShadow> shadow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.rLg + 4),
          boxShadow: shadow,
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.rLg),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 15, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
