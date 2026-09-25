import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Driver subscription plans — list, add, edit, delete (local state).
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState
    extends State<AdminSubscriptionsScreen> {
  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Weekly',
      'price': 199,
      'days': 7,
      'features': ['Zero commission week', 'Priority support'],
      'active': true,
    },
    {
      'name': 'Monthly',
      'price': 499,
      'days': 30,
      'features': [
        'Zero commission',
        'Priority support',
        'Free cancellation listing'
      ],
      'active': true,
    },
    {
      'name': 'Quarterly',
      'price': 1299,
      'days': 90,
      'features': ['Sab kuch Monthly wala', 'Extra 2% discount'],
      'active': true,
    },
  ];

  Future<void> _planDialog({Map<String, dynamic>? existing, int? index}) async {
    final nameCtrl =
        TextEditingController(text: existing?['name']?.toString() ?? '');
    final priceCtrl =
        TextEditingController(text: existing?['price']?.toString() ?? '');
    final daysCtrl =
        TextEditingController(text: existing?['days']?.toString() ?? '');
    final featCtrl = TextEditingController(
        text: existing != null
            ? (existing['features'] as List).join(', ')
            : '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Naya Plan' : 'Plan Edit Karo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Plan name')),
              const SizedBox(height: 10),
              TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Price (₹)')),
              const SizedBox(height: 10),
              TextField(
                  controller: daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Validity (days)')),
              const SizedBox(height: 10),
              TextField(
                  controller: featCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Features (comma se alag karo)',
                      hintText: 'Zero commission, Priority support')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (saved == true) {
      final name = nameCtrl.text.trim();
      final price = int.tryParse(priceCtrl.text.trim());
      final days = int.tryParse(daysCtrl.text.trim());
      if (name.isEmpty || price == null || days == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Naam, price aur days sahi dalen.'),
              backgroundColor: AppTheme.error),
        );
      } else {
        final features = featCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        setState(() {
          final plan = {
            'name': name,
            'price': price,
            'days': days,
            'features': features,
            'active': existing?['active'] ?? true,
          };
          if (index == null) {
            _plans.add(plan);
          } else {
            _plans[index] = plan;
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Plan save ho gaya.'),
              backgroundColor: AppTheme.success),
        );
      }
    }

    nameCtrl.dispose();
    priceCtrl.dispose();
    daysCtrl.dispose();
    featCtrl.dispose();
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Plan delete karo?'),
        content: Text(' "${_plans[index]['name']}" hamesha ke liye hat jayega.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _plans.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Subscriptions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _planDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _plans.isEmpty
          ? const Center(
              child: Text('Koi plan nahi. + se naya banao.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (c, i) {
                final p = _plans[i];
                final active = p['active'] == true;
                final features =
                    (p['features'] as List).map((e) => e.toString()).toList();
                return Opacity(
                  opacity: active ? 1 : 0.55,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(p['name'].toString(),
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                            ),
                            Switch(
                              value: active,
                              activeColor: AppTheme.primary,
                              onChanged: (v) => setState(
                                  () => _plans[i]['active'] = v),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text('₹${p['price']}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary)),
                            const SizedBox(width: 8),
                            Text('/ ${p['days']} din',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...features.map((f) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 16, color: AppTheme.success),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(f,
                                          style: const TextStyle(
                                              fontSize: 13.5))),
                                ],
                              ),
                            )),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18),
                              label: const Text('Edit'),
                              onPressed: () => _planDialog(
                                  existing: p, index: i),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18),
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.error),
                              onPressed: () => _delete(i),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
