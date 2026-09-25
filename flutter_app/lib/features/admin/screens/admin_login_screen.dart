import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/auth/msg91_service.dart';

/// Admin sign-in: phone -> MSG91 OTP (role 'admin') -> /admin/dashboard.
/// Non-admin numbers are rejected after OTP verification.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  int _step = 0; // 0 = phone, 1 = otp
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Phone number required';
    final digits = val.replaceAll(' ', '');
    if (digits.length != 10) return 'Enter a valid 10-digit number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final sent = await Msg91Service.sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);

    if (sent) {
      setState(() => _step = 1);
    } else {
      setState(() => _error = 'OTP bhejne me dikkat aayi. Phir try karo.');
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sent = await Msg91Service.sendOtp(_phoneCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = sent ? null : 'Resend failed. Phir try karo.';
    });
  }

  Future<void> _verify(String otp) async {
    if (otp.length < 6 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await Msg91Service.verifyOtp(_phoneCtrl.text.trim(), otp, 'admin');

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'Galat OTP. Dobara try karo.';
      });
      _pinCtrl.clear();
      return;
    }

    final session = result['session'] as Map<String, dynamic>?;
    if (session != null) {
      await AuthService.setSessionFromBackend(
        accessToken: session['access_token'] as String,
        refreshToken: session['refresh_token'] as String,
      );
    }

    final user = result['user'] as Map<String, dynamic>?;
    final role = user?['role']?.toString() ?? 'admin';

    if (!mounted) return;
    setState(() => _loading = false);

    // Hard gate: only admin role may enter the admin panel.
    if (role != 'admin') {
      await AuthService.signOut();
      if (!mounted) return;
      setState(() {
        _error = 'Ye number admin account se linked nahi hai.';
        _step = 0;
      });
      _pinCtrl.clear();
      return;
    }

    context.go('/admin/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          child: _step == 0 ? _phoneStep(theme) : _otpStep(theme),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, IconData icon, String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFE65100), size: 32),
        ),
        const SizedBox(height: 24),
        Text(title,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(sub,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _phoneStep(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme, Icons.admin_panel_settings_outlined, 'Admin Login',
              'Admin panel me jaane ke liye apna registered number dalen.'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: _validatePhone,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 2),
            decoration: InputDecoration(
              prefixText: '+91  ',
              prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100)),
              hintText: '98765 43210',
              hintStyle: TextStyle(color: Colors.grey[400], letterSpacing: 2),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Send OTP',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _otpStep(ThemeData theme) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(theme, Icons.lock_outline_rounded, 'Verify OTP',
            'Admin number ${_phoneCtrl.text.trim()} pe bheja gaya 6-digit OTP dalen.'),
        Center(
          child: Pinput(
            controller: _pinCtrl,
            length: 6,
            autofocus: true,
            keyboardType: TextInputType.number,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border:
                    Border.all(color: const Color(0xFFE65100), width: 2),
              ),
            ),
            onCompleted: _verify,
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Center(
            child: Text(_error!,
                style: const TextStyle(color: AppTheme.error)),
          ),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFFE65100)),
          ),
        const Spacer(),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _resend,
            child: const Text('Resend OTP',
                style: TextStyle(
                    color: Color(0xFFE65100), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : () => _verify(_pinCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
            ),
            child: const Text('Verify & Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
