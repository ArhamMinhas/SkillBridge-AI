import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wraps [Shimmer] with SkillBridge's shimmer color tokens so every
/// skeleton screen looks consistent regardless of theme.
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor:
          isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// A single rounded-rectangle skeleton block — compose several inside
/// [AppShimmer] to mimic a card's final layout (image block, title line,
/// subtitle line, etc).
class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBlock({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton mimicking a typical card list item (avatar/title/subtitle).
class ShimmerCardSkeleton extends StatelessWidget {
  const ShimmerCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            ShimmerBlock(width: 48, height: 48, borderRadius: 12),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(height: 14, width: 140),
                  SizedBox(height: 8),
                  ShimmerBlock(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
