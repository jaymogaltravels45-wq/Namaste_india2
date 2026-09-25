import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Push-style notifications composer + sent history (local state).
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends State<AdminNotificationsScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  final List<Map<String, dynamic>> _sent = [
    {
      'title': 'Diwali Offer Live!',
      'message': 'Outstation trips par 10% off — code DIWALI10 lagao.',
      'audience': 'all',
      'time': 'Aaj, 9:00 AM',
      'count': 1240,
    },
    {
      'title': 'Wallet Bonus',
      'message': 'Is hafte 20+ trips par ₹500 bonus jeeto.',
      'audience': 'drivers',
      'time': 'Kal, 5:30 PM',
      'count': 86,
    },
  ];

  static const _audiences = {
    'all': 'Sabhi Users',
    'customers': 'Sirf Customers',
    'drivers': 'Sirf Drivers',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final msg = _msgCtrl.text.trim();
    if (title.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title aur message dono likho.'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final count = _audience == 'drivers'
        ? 86
        : _audience == 'customers'
            ? 1154
            : 1240;

    setState(() {
      _sent.insert(0, {
        'title': title,
        'message': msg,
        'audience': _audience,
        'time': 'Abhi',
        'count': count,
      });
      _sending = false;
    });
    _titleCtrl.clear();
    _msgCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Notification $count users ko bhej di gayi (${_audiences[_audience]}).'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Composer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nayi Notification',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _msgCtrl,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Message'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _audience,
                  items: _audiences.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _audience = v ?? 'all'),
                  decoration:
                      const InputDecoration(labelText: 'Audience'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_sending ? 'Bhej rahe hain…' : 'Send'),
                    onPressed: _sending ? null : _send,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Bheji hui notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._sent.map((n) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n['title'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                              _audiences[n['audience']] ??
                                  n['audience'].toString(),
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(n['message'].toString(),
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(
                        '${n['time']} • ${n['count']} users tak pahunchi',
                        style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11.5)),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
