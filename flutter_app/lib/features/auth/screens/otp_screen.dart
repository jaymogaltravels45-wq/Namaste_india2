import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../services/auth/msg91_service.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String role;
  final String reqId;
  const OtpScreen({super.key, required this.phone, required this.role, required this.reqId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendCountdown = 30;
  late String _reqId = widget.reqId; // refreshed on every resend
  late final _countdownTimer = _startCountdown();

  @override
  void initState() {
    super.initState();
    _countdownTimer;
  }

  dynamic _startCountdown() {
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
    super.dispose();
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < 6) return;
    setState(() { _loading = true; _error = null; });

    final result = await Msg91Service.verifyOtp(widget.phone, otp, widget.role, _reqId);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result == null) {
      setState(() => _error = 'Invalid OTP. Please try again.');
      _pinCtrl.clear();
      return;
    }

    // Set Supabase session from backend tokens
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

    // New user -> profile setup; existing user -> home
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
    setState(() { _resending = true; _error = null; });

    final reqId = await Msg91Service.sendOtp(widget.phone);
    if (!mounted) return;

    setState(() {
      _resending = false;
      _resendCountdown = 30;
      if (reqId != null) {
        _reqId = reqId;
        _error = null;
      } else {
        _error = 'Failed to resend OTP.';
      }
    });

    // Mock mode (testing): show the OTP that "arrived" so the tester can enter it.
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
    // Show last 4 digits only for privacy
    final masked = '${fmt.substring(0, fmt.length - 4)}****';

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppTheme.primaryColor, size: 32),
              ),
              const SizedBox(height: 28),

              Text(
                'Verify OTP',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit OTP sent to $masked',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // PIN input
              Center(
                child: Pinput(
                  controller: _pinCtrl,
                  length: 6,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                      color: AppTheme.primaryColor.withOpacity(0.06),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                  ),
                  onCompleted: _verifyOtp,
                  errorText: _error,
                ),
              ),

              const SizedBox(height: 28),

              // Loading indicator
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),

              // Resend row
              if (!_loading)
                Center(
                  child: TextButton(
                    onPressed: _resendCountdown == 0 ? _resendOtp : null,
                    child: _resending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          )
                        : Text(
                            _resendCountdown > 0
                                ? 'Resend OTP in ${_resendCountdown}s'
                                : 'Resend OTP',
                            style: TextStyle(
                              color: _resendCountdown == 0
                                  ? AppTheme.primaryColor
                                  : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

              const Spacer(),

              // Verify button (for users who don't auto-submit)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _verifyOtp(_pinCtrl.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
