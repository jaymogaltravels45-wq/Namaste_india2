import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/msg91_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

class PhoneLoginScreen extends StatefulWidget {
  final String role;
  const PhoneLoginScreen({super.key, required this.role});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validatePhone(String? val) {
    if (val == null || val.isEmpty) return 'Phone number zaroori hai';
    final digits = val.replaceAll(' ', '');
    if (digits.length != 10) return 'Sahi 10-digit number daalo';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Sahi Indian mobile number daalo';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final phone = _phoneCtrl.text.trim();
    final reqId = await Msg91Service.sendOtp(phone);

    setState(() => _loading = false);

    if (!mounted) return;

    if (reqId != null) {
      final mockOtp = Msg91Service.lastMockOtp;
      if (mockOtp != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mock OTP (testing): $mockOtp'),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 10),
          ),
        );
      }
      context.push('/otp',
          extra: {'phone': phone, 'role': widget.role, 'reqId': reqId});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP bhejne me problem hui. Try Again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDriver = widget.role == 'driver';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          PremiumHeader(
            title: isDriver ? 'Driver Login' : 'Welcome back',
            subtitle: 'OTP se secure login',
            height: 170,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overlapping card
                    Transform.translate(
                      offset: const Offset(0, -34),
                      child: Entrance(
                        child: PremiumCard(
                          padding: const EdgeInsets.all(22),
                          shadows: AppTheme.shadowMd,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.blueGradient,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.phone_android_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mobile Number',
                                          style: theme
                                              .textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '6-digit OTP bhejenge',
                                          style: theme
                                              .textTheme.bodyMedium
                                              ?.copyWith(fontSize: 12.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                autofocus: true,
                                validator: _validatePhone,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '+91  ',
                                  prefixStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                  hintText: '98765 43210',
                                  hintStyle: const TextStyle(
                                    color: AppTheme.textTertiary,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceTint,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.rMd),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Entrance(
                      delayMs: 120,
                      child: Row(
                        children: const [
                          Icon(Icons.lock_rounded,
                              size: 14,
                              color: AppTheme.success),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tumhara number encrypted rehta hai — kabhi share nahi hota.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Entrance(
                      delayMs: 200,
                      child: PremiumButton(
                        label: 'Send OTP',
                        icon: Icons.sms_rounded,
                        loading: _loading,
                        onPressed: _sendOtp,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Continue karke aap Terms & Privacy Policy se\nsehamat hote ho.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textTertiary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
