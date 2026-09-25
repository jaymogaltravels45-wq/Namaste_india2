import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CustomerOffersScreen extends StatelessWidget {
  const CustomerOffersScreen({super.key});

  static const _offers = [
    {
      'code': 'FLAT50',
      'title': '₹50 off',
      'desc': 'Pehli ride pe ₹50 ki chhoot. Minimum fare ₹199.',
      'color': 0xFF1565C0,
      'icon': 'celebration',
    },
    {
      'code': 'OUTSTATION10',
      'title': '10% off',
      'desc': 'Outstation trips pe 10% discount, max ₹300 tak.',
      'color': 0xFF2E7D32,
      'icon': 'directions_car',
    },
    {
      'code': 'LOCAL20',
      'title': '20% off',
      'desc': 'Local packages pe 20% ki chhoot, max ₹200 tak.',
      'color': 0xFFE65100,
      'icon': 'location_city',
    },
    {
      'code': 'REFER100',
      'title': '₹100 referral',
      'desc': 'Dost ko invite karo, dono ko ₹100 ka fayda.',
      'color': 0xFF6A1B9A,
      'icon': 'group_add',
    },
  ];

  IconData _iconFor(String name) {
    switch (name) {
      case 'directions_car':
        return Icons.directions_car;
      case 'location_city':
        return Icons.location_city;
      case 'group_add':
        return Icons.group_add;
      default:
        return Icons.celebration;
    }
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Code $code copy ho gaya! Booking me use karo.'),
      backgroundColor: AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Offers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _heroCard(),
          const SizedBox(height: 16),
          ..._offers.map((o) => _offerCard(
                context,
                o['code'] as String,
                o['title'] as String,
                o['desc'] as String,
                Color(o['color'] as int),
                _iconFor(o['icon'] as String),
              )),
          const SizedBox(height: 8),
          Text(
            'Offer code booking ke time lagao. Ek booking pe ek hi code chalega.',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dhamakedaar Offers!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text(
                      'Code copy karo aur booking pe discount pao.',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.local_offer,
                  color: Colors.white, size: 36),
            ),
          ],
        ),
      );

  Widget _offerCard(BuildContext context, String code, String title,
      String desc, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _copyCode(context, code),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: color, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                        color: color.withOpacity(0.08),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(code,
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 13)),
                          const SizedBox(width: 8),
                          Icon(Icons.copy,
                              size: 15, color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
