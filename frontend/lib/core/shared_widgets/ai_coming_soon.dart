import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Shown wherever a screen calls an AI/ML backend endpoint that's wired
/// end-to-end but still returns 501 (app/ai/ or app/ml/ implementation
/// pending) — keeps that state consistent across every AI-dependent screen
/// instead of surfacing a raw error.
class AiComingSoon extends StatelessWidget {
  final String feature;
  final VoidCallback? onRetry;

  const AiComingSoon({super.key, required this.feature, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.auto_awesome_rounded,
      title: '$feature is almost ready',
      message: 'Our AI engine for this feature is still being wired up on '
          'the backend — check back soon.',
      actionLabel: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
    );
  }
}

/// True when [statusCode] is 501 (Not Implemented) — the convention this
/// backend uses for AI/ML endpoints that are routed and rate-limited but
/// whose model logic hasn't landed yet.
bool isFeaturePending(int? statusCode) => statusCode == 501;

/// True when [statusCode] is 503 (Service Unavailable) — the AI endpoint is
/// implemented but the upstream provider (Gemini/OpenAI) has no API key
/// configured yet, or is temporarily down.
bool isProviderUnavailable(int? statusCode) => statusCode == 503;
