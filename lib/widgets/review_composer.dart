import 'package:flutter/material.dart';

import '../data/app_scope.dart';

/// A modal that lets the guest rate a table and leave a written review.
///
/// Shown after a completed booking — the parent passes [eventId] and the
/// composer handles the API call via AppState.
class ReviewComposer extends StatefulWidget {
  const ReviewComposer({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  final String eventId;
  final String eventTitle;

  /// Shows the composer as a modal bottom sheet.
  static Future<bool?> show(
    BuildContext context, {
    required String eventId,
    required String eventTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewComposer(eventId: eventId, eventTitle: eventTitle),
    );
  }

  @override
  State<ReviewComposer> createState() => _ReviewComposerState();
}

class _ReviewComposerState extends State<ReviewComposer> {
  int _rating = 5;
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Review ${widget.eventTitle}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Star picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: star <= _rating
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = star),
                );
              }),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _controller,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Tell others about your experience…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.length < 10) return;
    setState(() => _submitting = true);
    try {
      await context.app.submitReview(
        widget.eventId,
        rating: _rating.toDouble(),
        text: text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _submitting = false);
      }
    }
  }
}
