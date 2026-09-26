import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';
import '../../../services/auth/auth_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _phone = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _headers() {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer \$token',
    };
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(
        Uri.parse('\${AppConfig.apiBaseUrl}/customers/profile'),
        headers: _headers(),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        final user = body['user'] as Map<String, dynamic>? ?? {};
        setState(() {
          _nameCtrl.text = user['name']?.toString() ?? '';
          _emailCtrl.text = user['email']?.toString() ?? '';
          _phone = user['phone']?.toString() ?? AuthService.phone ?? '';
          _loading = false;
        });
      } else {
        setState(() {
          _error = body['message']?.toString() ?? 'Could not load profile';
          _phone = AuthService.phone ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Network error';
          _phone = AuthService.phone ?? '';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Please enter your name', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await http.patch(
        Uri.parse('\${AppConfig.apiBaseUrl}/customers/profile'),
        headers: _headers(),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        }),
      );
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (res.statusCode == 200 && body['success'] == true) {
        _snack('Profile updated successfully');
      } else {
        _snack(body['message']?.toString() ?? 'Update failed', error: true);
      }
    } catch (_) {
      _snack('Network error. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.signOut();
    if (mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading ? _buildSkeleton() : _buildBody(),
      bottomNavigationBar:
          const AppBottomNav(currentIndex: 3, isDriver: false),
    );
  }

  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.rXl)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              const SkeletonDetailCard(),
              const SizedBox(height: 16),
              const SkeletonDetailCard(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final initials = _nameCtrl.text.trim().isNotEmpty
        ? _nameCtrl.text.trim()[0].toUpperCase()
        : _phone.isNotEmpty
            ? _phone[_phone.length - 1]
            : 'C';

    return CustomScrollView(
      slivers: [
        // ── Hero header
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.rXl)),
            ),
            child: Stack(
              children: [
                Positioned(right: -40, top: -30,
                    child: _blob(140, Colors.white.withOpacity(0.07))),
                Positioned(left: -20, bottom: -40,
                    child: _blob(110, AppTheme.gold.withOpacity(0.10))),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text('My Profile',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 22,
                                    fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                            const Spacer(),
                            GestureDetector(
                              onTap: _logout,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.25)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.logout_rounded,
                                        color: Colors.white, size: 15),
                                    SizedBox(width: 6),
                                    Text('Sign out',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Avatar
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            shape: BoxShape.circle,
                            boxShadow: AppTheme.shadowGold,
                          ),
                          child: Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 34,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _nameCtrl.text.trim().isNotEmpty
                              ? _nameCtrl.text.trim()
                              : 'Your Name',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(_phone,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Edit Form
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorSoft,
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppTheme.error, fontSize: 13))),
                    ],
                  ),
                ),

              _section('Personal Information', Icons.person_outline_rounded),
              const SizedBox(height: 12),
              _field(label: 'Full Name', controller: _nameCtrl,
                  icon: Icons.badge_outlined,
                  hint: 'Enter your full name'),
              const SizedBox(height: 12),
              _field(label: 'Email Address', controller: _emailCtrl,
                  icon: Icons.email_outlined,
                  hint: 'Enter your email',
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _readOnly(label: 'Mobile Number', value: _phone,
                  icon: Icons.phone_outlined),
              const SizedBox(height: 24),
              PremiumButton(
                label: 'Save Changes',
                onPressed: _save,
                loading: _saving,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 20),

              _section('Quick Actions', Icons.grid_view_rounded),
              const SizedBox(height: 12),
              _actionGrid(context),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: AppTheme.primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.shadowSm,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppTheme.textTertiary),
              prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnly({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppTheme.surfaceTint,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.textTertiary, size: 20),
              const SizedBox(width: 12),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, color: AppTheme.textSecondary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.successSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Verified',
                    style: TextStyle(
                        color: AppTheme.success, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionGrid(BuildContext context) {
    final actions = [
      _Action(Icons.history_rounded, 'My Trips', AppTheme.primary,
          () => context.go('/customer/history')),
      _Action(Icons.account_balance_wallet_rounded, 'Wallet', const Color(0xFF2E7D32),
          () => context.go('/customer/wallet')),
      _Action(Icons.local_offer_rounded, 'Offers', const Color(0xFFE65100),
          () {}),
      _Action(Icons.headset_mic_rounded, 'Support', const Color(0xFF6A1B9A),
          () {}),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: actions.map((a) => GestureDetector(
        onTap: a.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: a.color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            border: Border.all(color: a.color.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(a.icon, color: a.color, size: 20),
              const SizedBox(width: 10),
              Text(a.label,
                  style: TextStyle(
                      color: a.color, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _blob(double s, Color c) =>
      Container(width: s, height: s, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.icon, this.label, this.color, this.onTap);
}
