import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// CMS: app banners / notices — add, edit, toggle, delete (local state).
class AdminCmsScreen extends StatefulWidget {
  const AdminCmsScreen({super.key});

  @override
  State<AdminCmsScreen> createState() => _AdminCmsScreenState();
}

class _AdminCmsScreenState extends State<AdminCmsScreen> {
  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Diwali Dhamaka Offer',
      'text': 'Outstation trips par 10% off — code DIWALI10',
      'active': true,
    },
    {
      'title': 'Safety First',
      'text': 'Har trip me SOS button aur live tracking uplabdh hai.',
      'active': true,
    },
    {
      'title': 'Driver Bonus Week',
      'text': 'Is hafte 20+ trips par ₹500 bonus!',
      'active': false,
    },
  ];

  Future<void> _editDialog({Map<String, dynamic>? existing, int? index}) async {
    final titleCtrl =
        TextEditingController(text: existing?['title']?.toString() ?? '');
    final textCtrl =
        TextEditingController(text: existing?['text']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Naya Banner' : 'Banner Edit Karo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration:
                    const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Text / description'),
            ),
          ],
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
      final title = titleCtrl.text.trim();
      final text = textCtrl.text.trim();
      if (title.isEmpty || text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Title aur text dono zaroori hain.'),
              backgroundColor: AppTheme.error),
        );
      } else {
        setState(() {
          final item = {
            'title': title,
            'text': text,
            'active': existing?['active'] ?? true,
          };
          if (index == null) {
            _items.add(item);
          } else {
            _items[index] = item;
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Banner save ho gaya.'),
              backgroundColor: AppTheme.success),
        );
      }
    }
    titleCtrl.dispose();
    textCtrl.dispose();
  }

  Future<void> _delete(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete karo?'),
        content:
            Text('"${_items[index]['title']}" hat jayega.'),
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
    if (ok == true) setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('CMS — Banners & Notices')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text('Koi banner nahi. + se naya banao.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (c, i) {
                final item = _items[i];
                final active = item['active'] == true;
                return Opacity(
                  opacity: active ? 1 : 0.55,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0D47A1),
                                Color(0xFF1976D2)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: active ? null : AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: active
                          ? null
                          : Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(item['title'].toString(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? Colors.white
                                          : AppTheme.textPrimary)),
                            ),
                            Switch(
                              value: active,
                              activeColor: Colors.white,
                              activeTrackColor:
                                  Colors.white.withOpacity(0.4),
                              onChanged: (v) => setState(
                                  () => _items[i]['active'] = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item['text'].toString(),
                            style: TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: active
                                    ? Colors.white70
                                    : AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: Icon(Icons.edit_outlined,
                                  size: 18,
                                  color: active
                                      ? Colors.white
                                      : AppTheme.primary),
                              label: Text('Edit',
                                  style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : AppTheme.primary)),
                              onPressed: () => _editDialog(
                                  existing: item, index: i),
                            ),
                            TextButton.icon(
                              icon: Icon(Icons.delete_outline,
                                  size: 18,
                                  color: active
                                      ? Colors.white70
                                      : AppTheme.error),
                              label: Text('Delete',
                                  style: TextStyle(
                                      color: active
                                          ? Colors.white70
                                          : AppTheme.error)),
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
