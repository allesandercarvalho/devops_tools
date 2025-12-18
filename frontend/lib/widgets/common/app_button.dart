import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppButtonType { primary, secondary, outline, destructive, ghost, success }

class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final bool isSmall;

  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isSmall 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    
    final fontSize = isSmall ? 13.0 : 14.0;
    final iconSize = isSmall ? 16.0 : 20.0;

    switch (type) {
      case AppButtonType.primary:
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, Colors.white),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: padding,
          ),
        );
      case AppButtonType.secondary:
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, AppTheme.primary),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            foregroundColor: AppTheme.primary,
            padding: padding,
            elevation: 0,
          ),
        );
      case AppButtonType.outline:
        return OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, AppTheme.primary),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary),
            padding: padding,
          ),
        );
      case AppButtonType.destructive:
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, Colors.white),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            padding: padding,
          ),
        );
      case AppButtonType.success:
        return ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, Colors.white),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            padding: padding,
          ),
        );
      case AppButtonType.ghost:
        return TextButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: _buildIcon(iconSize, AppTheme.textSecondary),
          label: Text(label, style: TextStyle(fontSize: fontSize)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
            padding: padding,
          ),
        );
    }
  }

  Widget _buildIcon(double size, Color color) {
    if (isLoading) {
      return SizedBox(
        width: size, 
        height: size, 
        child: CircularProgressIndicator(strokeWidth: 2, color: color)
      );
    }
    if (icon != null) {
      return Icon(icon, size: size);
    }
    return const SizedBox.shrink();
  }
}
