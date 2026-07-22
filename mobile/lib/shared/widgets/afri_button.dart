import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AfriButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDestructive;
  final IconData? icon;

  const AfriButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(context, AfriTheme.rangelandGreen),
      );
    }

    final color = isDestructive ? AfriTheme.hazardRed : AfriTheme.rangelandGreen;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color),
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(context, Colors.white),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    if (isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ],
      );
    }

    return Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold));
  }
}
