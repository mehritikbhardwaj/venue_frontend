import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Centered loading spinner. Used wherever a provider is in ViewState.loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.brand),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(
              label!,
              style: const TextStyle(color: AppTheme.inkMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state with a retry button. Used wherever a provider hits ViewState.error.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // ListView so it still works as a RefreshIndicator child (scrollable).
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        _IconBubble(
          icon: Icons.cloud_off_rounded,
          color: AppTheme.danger,
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.ink),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(140, 48),
                fixedSize: const Size(160, 48),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state with an optional action. Used for ViewState.empty.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_rounded, this.action});
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      children: [
        _IconBubble(icon: icon, color: AppTheme.brand),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.ink, height: 1.4),
        ),
        if (action != null) ...[const SizedBox(height: 20), Center(child: action!)],
      ],
    );
  }
}

/// Soft rounded bubble holding a state icon.
class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 42, color: color),
      ),
    );
  }
}
