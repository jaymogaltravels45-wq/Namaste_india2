import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium.dart';

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
            Entrance(child: _balanceCard()),
            const SizedBox(height: 16),
            Entrance(delayMs: 100, child: _infoCard()),
            const SizedBox(height: 18),
            const SectionTitle(title: 'Transactions'),
            const SizedBox(height: 10),
            Entrance(delayMs: 160, child: _emptyTransactions()),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: PremiumButton(
                    label: 'Book a Ride',
                    icon: Icons.add_rounded,
                    height: 50,
                    onPressed: () => context.go('/customer/booking'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/customer/history'),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('Meri Trips'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.rMd)),
                      ),
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
          gradient: AppTheme.heroGradient,
          borderRadius: BorderRadius.circular(AppTheme.rLg),
          boxShadow: AppTheme.shadowBlue,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.14),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Namaste Wallet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.gold.withOpacity(0.4)),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: AppTheme.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Total Balance',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 2),
                const Text('₹0',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1)),
                const SizedBox(height: 8),
                Text(
                  'Customer ke liye wallet jald aa raha hai. Abhi ride ka payment Cash ya UPI se hota hai.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _infoCard() => PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Payment kaise hota hai?',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14.5)),
            SizedBox(height: 12),
            _InfoRow(
                icon: Icons.money_rounded,
                text: 'Cash — ride khatam hone pe driver ko de do'),
            SizedBox(height: 10),
            _InfoRow(
                icon: Icons.qr_code_rounded,
                text: 'UPI — company ke QR pe direct payment'),
            SizedBox(height: 10),
            _InfoRow(
                icon: Icons.receipt_rounded,
                text: 'Har payment booking detail me dikhega'),
          ],
        ),
      );

  Widget _emptyTransactions() => const PremiumEmpty(
        icon: Icons.receipt_long_rounded,
        title: 'Abhi koi transaction nahi hai',
        subtitle: 'Tumhari saari payments yahin dikhengi.',
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textPrimary))),
        ],
      );
}
