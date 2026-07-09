import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final double? height;
  final IconData? icon;
  final Widget? leading;
  final Color? color;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.height,
    this.icon,
    this.leading,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = theme.extension<AppMetrics>() ?? AppMetrics.standard();

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined
                    ? (color ?? theme.colorScheme.primary)
                    : theme.colorScheme.onPrimary,
              ),
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: metrics.space8),
              ] else if (icon != null) ...[
                Icon(icon, size: 20),
                SizedBox(width: metrics.space8),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          );

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(width ?? double.infinity, height ?? 54),
      ),
      backgroundColor: color != null && !isOutlined
          ? WidgetStateProperty.all(color)
          : null,
      foregroundColor: color != null
          ? WidgetStateProperty.all(isOutlined ? color : theme.colorScheme.onPrimary)
          : null,
      side: color != null && isOutlined
          ? WidgetStateProperty.all(BorderSide(color: color!, width: 1.5))
          : null,
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style:
            theme.outlinedButtonTheme.style?.merge(buttonStyle) ?? buttonStyle,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: theme.elevatedButtonTheme.style?.merge(buttonStyle) ?? buttonStyle,
      child: child,
    );
  }
}
