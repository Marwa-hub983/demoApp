import 'package:flutter/material.dart';
import 'custom_button.dart';
import 'skeleton_loader.dart';
import '../theme/theme_extensions.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(metrics.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title/Header Shimmer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Skeleton(height: 28, width: 150),
                  Skeleton(
                    height: 36,
                    width: 36,
                    borderRadius: BorderRadius.circular(metrics.radiusRound),
                  ),
                ],
              ),
              SizedBox(height: metrics.space24),

              // 2. Search Box/Filter Shimmer Block
              const Skeleton(height: 48, width: double.infinity),
              SizedBox(height: metrics.space24),

              // 3. Optional Status Message
              if (message != null) ...[
                Padding(
                  padding: EdgeInsets.only(bottom: metrics.space12),
                  child: Text(
                    message!.toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],

              // 4. Listing Blueprint Skeletons
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: metrics.space16),
                  itemBuilder: (context, index) => Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Skeleton(
                        height: 80,
                        width: 80,
                        borderRadius: BorderRadius.circular(metrics.radius12),
                      ),
                      SizedBox(width: metrics.space16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Skeleton(height: 16, width: 180),
                            SizedBox(height: 8),
                            Skeleton(height: 12, width: 120),
                            SizedBox(height: 8),
                            Skeleton(height: 12, width: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyView({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(metrics.space24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(metrics.space24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.6),
                ),
              ),
              SizedBox(height: metrics.space24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: metrics.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 14,
                ),
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                SizedBox(height: metrics.space24),
                CustomButton(
                  text: buttonText!,
                  onPressed: onButtonPressed!,
                  width: 200,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(metrics.space24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(metrics.space24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(height: metrics.space24),
              const Text(
                'An Error Occurred',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: metrics.space8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontSize: 14,
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: metrics.space24),
                CustomButton(text: 'Retry', onPressed: onRetry!, width: 150),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineView extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: 'No Connection',
      message:
          'It looks like you are offline. Please check your internet connection.',
      icon: Icons.wifi_off_outlined,
      buttonText: onRetry != null ? 'Try Again' : null,
      onButtonPressed: onRetry,
    );
  }
}
