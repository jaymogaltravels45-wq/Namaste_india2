import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../services/auth/msg91_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String role;
  final String reqId;
  const OtpScreen(
      {super.key,
      required this.phone,
      required this.role,
      required this.reqId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendCountdown = 30;
  late String _reqId = widget.reqId;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCountdown = (_resendCountdown - 1).clamp(0, 30));
      return _resendCountdown > 0;
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < 6) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await Msg91Service.verifyOtp(widget.phone, otp, widget.role, _reqId);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() => _error = 'Galat OTP. Dobara try karo.');
      _pinCtrl.clear();
      _shakeCtrl.forward(from: 0);
      return;
    }

    final session = result['session'] as Map<String, dynamic>?;
    if (session != null) {
      await AuthService.setSessionFromBackend(
        accessToken: session['access_token'] as String,
        refreshToken: session['refresh_token'] as String,
      );
    }

    if (!mounted) return;

    final user = result['user'] as Map<String, dynamic>?;
    final isNewUser = result['is_new_user'] == true;
    final role = user?['role'] as String? ?? widget.role;

    if (isNewUser) {
      context.go('/setup');
    } else {
      _navigateByRole(role);
    }
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'driver':
        context.go('/driver');
        break;
      case 'admin':
        context.go('/admin/dashboard');
        break;
      default:
        context.go('/customer');
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });

    final reqId = await Msg91Service.sendOtp(widget.phone);
    if (!mounted) return;

    setState(() {
      _resending = false;
      _resendCountdown = 30;
      if (reqId != null) {
        _reqId = reqId;
        _error = null;
      } else {
        _error = 'OTP dobara bhejne me problem hui.';
      }
    });

    final mockOtp = Msg91Service.lastMockOtp;
    if (reqId != null && mockOtp != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mock OTP (testing): $mockOtp'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 10),
        ),
      );
    }

    if (reqId != null) _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = Msg91Service.formatPhone(widget.phone);
    final masked = '${fmt.substring(0, fmt.length - 4)}****';

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: AppTheme.border, width: 1.5),
        boxShadow: AppTheme.shadowSm,
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          PremiumHeader(
            title: 'OTP Verify karo',
            subtitle: '+91 $masked par bheja gaya',
            height: 170,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -34),
                    child: Entrance(
                      child: PremiumCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        shadows: AppTheme.shadowMd,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppTheme.goldGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppTheme.shadowGold,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '6-digit code daalo',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 20),
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (_, child) {
                                final dx = _shake.value == 0
                                    ? 0.0
                                    : (1 - _shake.value) *
                                        10 *
                                        (_shake.value * 12 % 2 < 1
                                            ? 1
                                            : -1);
                                return Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: child,
                                );
                              },
                              child: Pinput(
                                controller: _pinCtrl,
                                length: 6,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                defaultPinTheme: defaultPinTheme,
                                focusedPinTheme:
                                    defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme
                                      .decoration!
                                      .copyWith(
                                    border: Border.all(
                                        color: AppTheme.primary,
                                        width: 2.2),
                                    boxShadow: AppTheme.shadowBlue,
                                  ),
                                ),
                                submittedPinTheme:
                                    defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme
                                      .decoration!
                                      .copyWith(
                                    border: Border.all(
                                        color: AppTheme.success,
                                        width: 1.8),
                                  ),
                                ),
                                errorPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme
                                      .decoration!
                                      .copyWith(
                                    border: Border.all(
                                        color: AppTheme.error,
                                        width: 1.8),
                                  ),
                                ),
                                onCompleted: _verifyOtp,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.error_outline_rounded,
                                        size: 15,
                                        color: AppTheme.error),
                                    const SizedBox(width: 6),
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (_loading)
                              const CircularProgressIndicator(
                                  color: AppTheme.primary)
                            else
                              TextButton(
                                onPressed: _resendCountdown == 0
                                    ? _resendOtp
                                    : null,
                                child: _resending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : Text(
                                        _resendCountdown > 0
                                            ? 'Resend OTP in ${_resendCountdown}s'
                                            : 'Resend OTP',
                                        style: TextStyle(
                                          color: _resendCountdown == 0
                                              ? AppTheme.primary
                                              : AppTheme.textTertiary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Entrance(
                    delayMs: 150,
                    child: PremiumButton(
                      label: 'Verify & Continue',
                      icon: Icons.verified_rounded,
                      loading: _loading,
                      onPressed: () =>
                          _verifyOtp(_pinCtrl.text),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
