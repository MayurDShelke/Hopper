import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';
import '../../core/errors/app_error.dart';

class ErrorBanner extends StatelessWidget {
  final AppError error;
  final VoidCallback? onFixPressed;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onFixPressed,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.space8),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: AppTokens.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTokens.error,
            size: 20,
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.title,
                  style: const TextStyle(
                    color: AppTokens.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  error.cause,
                  style: const TextStyle(
                    color: AppTokens.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Fix: ${error.fix}',
                  style: const TextStyle(
                    color: AppTokens.textMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          if (onFixPressed != null) ...[
            const SizedBox(width: AppTokens.space12),
            OutlinedButton(
              onPressed: onFixPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTokens.error),
                foregroundColor: AppTokens.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text('Fix', style: TextStyle(fontSize: 12)),
            ),
          ],
          if (onDismiss != null) ...[
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onDismiss,
              color: AppTokens.textMuted,
            ),
          ],
        ],
      ),
    );
  }
}
