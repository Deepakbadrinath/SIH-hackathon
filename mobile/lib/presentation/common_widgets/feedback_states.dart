import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import 'primary_button.dart';

/// 1. Standardized Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSubtle
                    : AppColors.primaryNavyLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                  width: 2.0,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: isDark ? AppColors.darkBorder : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: PrimaryButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onPressed: onAction,
                  height: 52,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 2. Standardized Loading State Widget
class LoadingStateWidget extends StatelessWidget {
  final String statusMessage;

  const LoadingStateWidget({
    super.key,
    this.statusMessage = 'Loading, please wait...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                color: isDark ? AppColors.darkBorder : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Standardized Error State Widget
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String errorMessage;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorStateWidget({
    super.key,
    this.title = 'Unable to Load Information',
    required this.errorMessage,
    this.onRetry,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSubtle
                    : AppColors.criticalRedLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkRed : AppColors.criticalRed,
                  width: 2.0,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: isDark ? AppColors.darkRed : AppColors.criticalRed,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: PrimaryButton(
                  label: retryLabel,
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  height: 52,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 4. Standardized Success State Widget
class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final Widget? primaryAction;

  const SuccessStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.primaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSubtle
                    : AppColors.clinicalJadeLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkJade : AppColors.clinicalJade,
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 44,
                color: isDark ? AppColors.darkJade : AppColors.clinicalJade,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            if (primaryAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              primaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}
