import 'package:flutter/material.dart';

import '../data/app_scope.dart';

/// A simple form that PATCHes the signed-in user's profile.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  final _tastes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final me = context.app.me;
    if (me != null) {
      _name.text = me.name;
      _city.text = me.city;
      _bio.text = me.bio;
      _tastes.text = me.tastes.join(', ');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _tastes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: _deco('Name'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _city,
            decoration: _deco('City'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bio,
            decoration: _deco('Bio'),
            maxLines: 3,
            minLines: 2,
            maxLength: 400,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tastes,
            decoration: _deco(
              'Tastes',
              hint: 'Natural wine, Japanese, Vegetarian',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          Text(
            'Separate tastes with commas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _deco(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final city = _city.text.trim();
    if (name.length < 2 || city.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and city must be at least 2 characters'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final tastes = _tastes.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await context.app.updateProfile(
        name: name,
        city: city,
        bio: _bio.text.trim(),
        tastes: tastes,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
