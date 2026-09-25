import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth/auth_service.dart';
import '../admin_api.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final Color color;
  const _NavItem(this.label, this.icon, this.route, this.color);
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  static const _sections = [
    _NavItem('Users', Icons.people_outline_rounded, '/admin/users', Color(0xFF1565C0)),
    _NavItem('Drivers', Icons.drive_eta_outlined, '/admin/drivers', Color(0xFF2E7D32)),
    _NavItem('KYC Requests', Icons.verified_user_outlined, '/admin/kyc', Color(0xFFE65100)),
    _NavItem('Bookings', Icons.receipt_long_outlined, '/admin/bookings', Color(0xFF6A1B9A)),
    _NavItem('Fares', Icons.currency_rupee_rounded, '/admin/fares', Color(0xFF00838F)),
    _NavItem('Wallets', Icons.account_balance_wallet_outlined, '/admin/wallets', Color(0xFFC2185B)),
    _NavItem('Penalties', Icons.gavel_outlined, '/admin/penalties', Color(0xFFD32F2F)),
    _NavItem('Subscriptions', Icons.card_membership_outlined, '/admin/subscriptions', Color(0xFF5D4037)),
    _NavItem('Support', Icons.support_agent_outlined, '/admin/support', Color(0xFF455A64)),
    _NavItem('CMS', Icons.web_outlined, '/admin/cms', Color(0xFF7B1FA2)),
    _NavItem('Notifications', Icons.notifications_outlined, '/admin/notifications', Color(0xFFEF6C00)),
    _NavItem('Analytics', Icons.bar_chart_outlined, '/admin/analytics', Color(0xFF0288D1)),
    _NavItem('Settings', Icons.settings_outlined, '/admin/settings', Color(0xFF616161)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApi.get('/api/admin/dashboard');
      if (!mounted) return;
      setState(() {
        _data = AdminApi.asMap(res['data']);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _inr(num v) {
    final s = v.round().toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Kya aap admin panel se logout karna chahte hain?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child:
                const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.signOut();
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
                ? _errorView()
                : _content(),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off_outlined,
            size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        const Text(
          'Data load nahi ho paya',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            onPressed: _load,
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    final customers = (_data['customers'] as num?)?.toInt() ?? 0;
    final drivers = (_data['drivers'] as num?)?.toInt() ?? 0;
    final bookings = (_data['bookings'] as num?)?.toInt() ?? 0;
    final pendingKyc = (_data['pendingKyc'] as num?)?.toInt() ?? 0;
    final revenue = (_data['revenue'] as num?) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue hero
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('₹${_inr(revenue)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Paid trips (cash + UPI)',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Stat cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _stat('Customers', '$customers', Icons.people_outline_rounded,
                const Color(0xFF1565C0), null),
            _stat('Drivers', '$drivers', Icons.drive_eta_outlined,
                const Color(0xFF2E7D32), null),
            _stat('Bookings', '$bookings', Icons.receipt_long_outlined,
                const Color(0xFF6A1B9A), null),
            _stat('Pending KYC', '$pendingKyc', Icons.verified_user_outlined,
                const Color(0xFFE65100),
                pendingKyc > 0 ? () => context.push('/admin/kyc') : null),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Manage',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: _sections.map(_navCard).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ),
                if (onTap != null)
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _navCard(_NavItem item) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
