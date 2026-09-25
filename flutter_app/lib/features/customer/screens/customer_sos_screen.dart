import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CustomerSosScreen extends StatelessWidget {
  const CustomerSosScreen({super.key});

  static const _contacts = [
    {'name': 'Police', 'number': '100', 'icon': Icons.local_police},
    {'name': 'Ambulance', 'number': '102', 'icon': Icons.medical_services},
    {'name': 'Women Helpline', 'number': '1090', 'icon': Icons.woman},
    {
      'name': 'Namaste India Support',
      'number': '1800-123-4567',
      'icon': Icons.support_agent
    },
  ];

  void _copyNumber(BuildContext context, String number, String name) {
    Clipboard.setData(ClipboardData(text: number));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name ka number copy ho gaya: $number'),
      backgroundColor: AppTheme.success,
    ));
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.error, size: 28),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'Tum surakshit ho? Neeche diye gaye emergency numbers pe turant call karo. Apne parivaar ko bhi apni trip ki jaankari de do.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Main surakshit hoon'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _copyNumber(context, '100', 'Police');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('100 Copy Karo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sosButton(context),
            const SizedBox(height: 16),
            const Text('Emergency Contacts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._contacts.map((c) => _contactTile(
                  context,
                  c['name'] as String,
                  c['number'] as String,
                  c['icon'] as IconData,
                )),
            const SizedBox(height: 16),
            _shareTripCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sosButton(BuildContext context) => GestureDetector(
        onTap: () => _showSosDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.error.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.sos, color: Colors.white, size: 56),
              SizedBox(height: 8),
              Text('SOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
              SizedBox(height: 4),
              Text('Emergency me dabao',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _contactTile(
          BuildContext context, String name, String number, IconData icon) =>
      Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.error),
          ),
          title: Text(name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(number,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          trailing: IconButton(
            icon: const Icon(Icons.copy, color: AppTheme.primary),
            onPressed: () => _copyNumber(context, number, name),
            tooltip: 'Number copy karo',
          ),
          onTap: () => _copyNumber(context, number, name),
        ),
      );

  Widget _shareTripCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share_location, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Trip Share Karo',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Ride shuru hone pe apna Ride OTP aur driver ki details apne parivaar ya doston ke saath share karo. Booking detail screen se OTP dekh sakte ho.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      );
}
