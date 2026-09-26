import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../services/auth/msg91_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  final String role;
  const PhoneLoginScreen({super.key, required this.role});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _shake.dispose();
    super.dispose();
  }

  bool get _isDriver => widget.role == 'driver';

  Future<void> _sendOtp() async {
    final raw = _phoneCtrl.text.trim().replaceAll(' ', '');
    if (raw.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(raw)) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number');
      _shake.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    // Format: +91XXXXXXXXXX
    final phone = '+91' + raw;

    try {
      // Msg91Service.sendOtp returns reqId (String?) on success, null on failure
      final reqId = await Msg91Service.sendOtp(phone);
      if (!mounted) return;

      if (reqId == null) {
        setState(() {
          _error = 'Could not send OTP. Please try again.';
          _loading = false;
        });
        _shake.forward(from: 0);
      } else {
        setState(() => _loading = false);
        // Pass phone, role AND reqId to OTP screen via go_router extra
        context.push('/otp', extra: {
          'phone': phone,
          'role': widget.role,
          'reqId': reqId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Gradient top half
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.44,
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
                      child: _blob(160, Colors.white.withOpacity(0.07))),
                  Positioned(
                      left: -20,
                      bottom: -30,
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
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Hero icon
                Entrance(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: _isDriver
                          ? AppTheme.goldGradient
                          : AppTheme.blueGradient,
                      shape: BoxShape.circle,
                      boxShadow: _isDriver
                          ? AppTheme.shadowGold
                          : AppTheme.shadowBlue,
                    ),
                    child: Icon(
                      _isDriver
                          ? Icons.drive_eta_rounded
                          : Icons.person_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Entrance(
                  delayMs: 80,
                  child: Text(
                    _isDriver ? 'Driver Login' : 'Welcome Back',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5),
                  ),
                ),
                Entrance(
                  delayMs: 120,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Enter your mobile number to continue',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // White card
                Expanded(
                  child: Entrance(
                    delayMs: 180,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.rXl),
                          boxShadow: AppTheme.shadowLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mobile Number',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.3)),
                            const SizedBox(height: 10),

                            // Shake on error
                            AnimatedBuilder(
                              animation: _shake,
                              builder: (_, child) => Transform.translate(
                                offset: Offset(
                                    _error != null
                                        ? 6 *
                                            (_shake.value < 0.5
                                                ? _shake.value * 2
                                                : (1 - _shake.value) * 2) *
                                            ((_shake.value * 10)
                                                    .toInt()
                                                    .isEven
                                                ? 1
                                                : -1)
                                        : 0,
                                    0),
                                child: child,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceTint,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.rMd),
                                  border: Border.all(
                                    color: _error != null
                                        ? AppTheme.error
                                        : AppTheme.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // +91 prefix
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 15),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                            right: BorderSide(
                                                color: AppTheme.border)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text('\u{1F1EE}\u{1F1F3}',
                                              style: TextStyle(fontSize: 18)),
                                          SizedBox(width: 8),
                                          Text('+91',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textPrimary)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _phoneCtrl,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly
                                        ],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 2,
                                            color: AppTheme.textPrimary),
                                        decoration: const InputDecoration(
                                          hintText: '00000 00000',
                                          hintStyle: TextStyle(
                                              letterSpacing: 1,
                                              color: AppTheme.textTertiary,
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 15),
                                          counterText: '',
                                        ),
                                        onSubmitted: (_) => _sendOtp(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 14, color: AppTheme.error),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            color: AppTheme.error,
                                            fontSize: 12.5)),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),

                            PremiumButton(
                              label: 'Send OTP',
                              onPressed: _sendOtp,
                              loading: _loading,
                              icon: Icons.send_rounded,
                              gradient: _isDriver
                                  ? AppTheme.goldGradient
                                  : AppTheme.blueGradient,
                              shadows: _isDriver
                                  ? AppTheme.shadowGold
                                  : AppTheme.shadowBlue,
                            ),

                            const SizedBox(height: 20),
                            const Text(
                              'By continuing, you agree to our Terms of Service and Privacy Policy.',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppTheme.textTertiary,
                                  height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}
