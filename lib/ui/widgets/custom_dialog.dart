import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A premium, unified dialog widget for the Timeflow application.
/// Supports custom title, content, actions, and uses a modern design.
class CustomDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool showCancelButton;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmColor;

  const CustomDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.showCancelButton = true,
    this.confirmText = "确定",
    this.cancelText = "取消",
    this.onConfirm,
    this.onCancel,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: theme.cardColor,
      elevation:
          0, // We handle shadow in container if needed, or rely on native elevation but 0 looks cleaner for custom style sometimes.
      // Let's use default elevation but with custom color
      // shadowColor: Colors.black.withOpacity(0.2), // Optional
      contentPadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.zero,
      actionsPadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
      content: Container(
        width: double.maxFinite,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          // Add subtle border for dark mode
          border: isDark
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Title Area
            if (title != null)
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 8.h),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),

            // 2. Content Area
            if (content != null)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: title != null ? 12.h : 24.h,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  child: content!,
                ),
              ),

            SizedBox(height: 16.h),

            // 3. Actions Area
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: IntrinsicHeight(
                child: Row(children: actions ?? _buildDefaultActions(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    return [
      if (showCancelButton)
        Expanded(
          child: _buildActionButton(
            context,
            label: cancelText,
            color: Theme.of(context).disabledColor,
            onTap: onCancel ?? () => Navigator.pop(context),
          ),
        ),
      if (showCancelButton)
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      Expanded(
        child: _buildActionButton(
          context,
          label: confirmText,
          color: confirmColor ?? Theme.of(context).primaryColor,
          isBold: true,
          onTap: onConfirm,
        ),
      ),
    ];
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isBold = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        bottomLeft: showCancelButton && label == cancelText
            ? Radius.circular(24.r)
            : Radius.zero,
        bottomRight: (!showCancelButton) || (label == confirmText)
            ? Radius.circular(24.r)
            : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Helper method to show the unified premium dialog with animations.
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    barrierDismissible: barrierDismissible,
    barrierLabel: "Dismiss",
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}
