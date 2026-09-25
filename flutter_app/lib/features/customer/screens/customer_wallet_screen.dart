import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class CustomerWalletScreen extends StatelessWidget {
  const CustomerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Mera Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _balanceCard(),
            const SizedBox(height: 16),
            _infoCard(),
            const SizedBox(height: 16),
            const Text('Transactions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _emptyTransactions(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/customer/booking'),
                    icon: const Icon(Icons.add),
                    label: const Text('Book a Ride'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/customer/history'),
                    icon: const Icon(Icons.history),
                    label: const Text('Meri Trips'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Colors.white70, size: 22),
                SizedBox(width: 8),
                Text('Namaste Wallet',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('₹0',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'Customer ke liye wallet jald aa raha hai. Abhi ride ka payment Cash ya UPI se hota hai.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment kaise hota hai?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 10),
            _InfoRow(
                icon: Icons.money,
                text: 'Cash — ride khatam hone pe driver ko de do'),
            SizedBox(height: 8),
            _InfoRow(
                icon: Icons.qr_code,
                text: 'UPI — company ke QR pe direct payment'),
            SizedBox(height: 8),
            _InfoRow(
                icon: Icons.receipt,
                text: 'Har payment booking detail me dikhega'),
          ],
        ),
      );

  Widget _emptyTransactions() => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 44, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 10),
            Text('Abhi koi transaction nahi hai',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      );
}
