import 'package:flutter/material.dart';

/// A loading / error / retry gate for list sections that fetch from the API.
///
/// Shows a centred spinner while [loading] is true, an error message with a
/// retry button when [error] is non-null and the list is empty, or the
/// [child] widget otherwise (even if the data is empty — the child decides
/// how to render an empty state).
class DcLoadGate extends StatelessWidget {
  const DcLoadGate({
    super.key,
    required this.loading,
    this.error,
    this.onRetry,
    required this.child,
  });

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
