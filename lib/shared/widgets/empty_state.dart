import 'package:flutter/material.dart';
import '../../app/theme/tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppTokens.textMuted,
            ),
            const SizedBox(height: AppTokens.space16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTokens.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTokens.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.space20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
