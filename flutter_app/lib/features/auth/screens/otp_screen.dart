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
  const OtpScreen({
    super.key,
    required this.phone,
    required this.role,
    required this.reqId,
  });

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
  late String _reqId;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  // Mock OTP shown as orange banner (only in test/mock mode)
  String? _mockOtp;

  @override
  void initState() {
    super.initState();
    _reqId = widget.reqId;
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shake = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    // Show mock OTP if backend returned one (test mode)
    _mockOtp = Msg91Service.lastMockOtp;

    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() =>
          _resendCountdown = (_resendCountdown - 1).clamp(0, 30));
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

    final result = await Msg91Service.verifyOtp(
      widget.phone,
      otp,
      widget.role,
      _reqId,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() => _error = 'Incorrect OTP. Please try again.');
      _pinCtrl.clear();
      _shakeCtrl.forward(from: 0);
      return;
    }

    // Save session from backend tokens
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
    try {
      // Msg91Service.sendOtp returns reqId on success
      final newReqId = await Msg91Service.sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendCountdown = 30;
        _pinCtrl.clear();
        if (newReqId != null) _reqId = newReqId;
        // Update mock OTP if new one came
        _mockOtp = Msg91Service.lastMockOtp;
      });
      _startCountdown();
    } catch (_) {
      if (mounted) setState(() => _resending = false);
    }
  }

  String get _maskedPhone {
    final p = widget.phone;
    if (p.length >= 4) return '${p.substring(0, p.length - 4)}****';
    return p;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Gradient top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: Stack(
                children: [
                  Positioned(
                      right: -40,
                      top: -30,
                      child: _blob(150, Colors.white.withOpacity(0.07))),
                  Positioned(
                      left: -20,
                      bottom: -40,
                      child: _blob(120, AppTheme.gold.withOpacity(0.10))),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // OTP icon
                Entrance(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.shadowBlue,
                    ),
                    child: const Icon(Icons.sms_rounded,
                        color: Colors.white, size: 42),
                  ),
                ),

                const SizedBox(height: 16),

                Entrance(
                  delayMs: 60,
                  child: const Text('Verify OTP',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5)),
                ),
                Entrance(
                  delayMs: 100,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Code sent to $_maskedPhone',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ─── MOCK OTP ORANGE BANNER (test mode only) ───
                if (_mockOtp != null)
                  Entrance(
                    delayMs: 120,
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF79009), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bug_report_rounded,
                              color: Color(0xFFF79009), size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('MOCK MODE — Test OTP:',
                                  style: TextStyle(
                                      color: Color(0xFFB45309),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(
                                _mockOtp!,
                                style: const TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_mockOtp != null) const SizedBox(height: 10),

                // White card
                Expanded(
                  child: Entrance(
                    delayMs: 160,
                    child: SingleChildScrollView(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.rXl),
                          boxShadow: AppTheme.shadowLg,
                        ),
                        child: Column(
                          children: [
                            // PIN boxes
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                  _error != null
                                      ? 8 *
                                          (_shake.value < 0.5
                                              ? _shake.value * 2
                                              : (1 - _shake.value) * 2) *
                                          ((_shake.value * 12)
                                                  .toInt()
                                                  .isEven
                                              ? 1
                                              : -1)
                                      : 0,
                                  0,
                                ),
                                child: child,
                              ),
                              child: Pinput(
                                controller: _pinCtrl,
                                length: 6,
                                autofocus: true,
                                onCompleted: _verifyOtp,
                                defaultPinTheme: PinTheme(
                                  width: 50,
                                  height: 56,
                                  textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceTint,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.border,
                                        width: 1.5),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 50,
                                  height: 56,
                                  textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoSoft,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.primary,
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                submittedPinTheme: PinTheme(
                                  width: 50,
                                  height: 56,
                                  textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primary),
                                  decoration: BoxDecoration(
                                    color: AppTheme.infoSoft,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.primary,
                                        width: 1.5),
                                  ),
                                ),
                                errorPinTheme: PinTheme(
                                  width: 50,
                                  height: 56,
                                  textStyle: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.error),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorSoft,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.error,
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 9),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorSoft,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.error_outline_rounded,
                                        size: 15,
                                        color: AppTheme.error),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(_error!,
                                          style: const TextStyle(
                                              color: AppTheme.error,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            PremiumButton(
                              label: _loading ? '' : 'Verify OTP',
                              onPressed: () =>
                                  _verifyOtp(_pinCtrl.text),
                              loading: _loading,
                              icon: Icons.verified_rounded,
                            ),

                            const SizedBox(height: 20),

                            // Resend row
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text("Didn't receive the code? ",
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13.5)),
                                _resendCountdown > 0
                                    ? Text(
                                        'Resend in ${_resendCountdown}s',
                                        style: const TextStyle(
                                            color: AppTheme.textTertiary,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600),
                                      )
                                    : GestureDetector(
                                        onTap: _resendOtp,
                                        child: _resending
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color:
                                                            AppTheme.primary))
                                            : const Text('Resend',
                                                style: TextStyle(
                                                    color: AppTheme.primary,
                                                    fontSize: 13.5,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double s, Color c) => Container(
      width: s,
      height: s,
      decoration:
          BoxDecoration(color: c, shape: BoxShape.circle));
}
