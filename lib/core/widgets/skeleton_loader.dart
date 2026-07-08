import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/theme_extensions.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorsExtension>();
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    
    final baseColor = colors?.shimmeringBase ?? const Color(0xFFE2E8F0);
    final highlightColor = colors?.shimmeringHighlight ?? const Color(0xFFF1F5F9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(metrics.radius8),
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(metrics.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Skeleton(
                borderRadius: BorderRadius.circular(metrics.radius12),
              ),
            ),
            SizedBox(height: metrics.space8),
            const Skeleton(height: 16, width: 120),
            SizedBox(height: metrics.space4),
            const Skeleton(height: 12, width: 80),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Skeleton(height: 16, width: 60),
                Skeleton(
                  height: 32,
                  width: 32,
                  borderRadius: BorderRadius.circular(metrics.radiusRound),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
