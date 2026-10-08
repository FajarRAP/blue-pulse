import 'package:material_ui/material_ui.dart';

/// Ergonomic UI extensions on [BuildContext] for theme, media queries, and notifications.
extension BuildContextX on BuildContext {
  // --- Theme Shortcuts ---
  ThemeData get theme => Theme.of(this);
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => scheme.brightness == .dark;

  // --- MediaQuery Shortcuts ---
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  // --- SnackBar Helper ---
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar({
    String? message,
    Widget? content,
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    Color? backgroundColor,
    Color? foregroundColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    SnackBarBehavior? behavior,
    bool clearPrevious = true,
  }) {
    assert(
      message != null || content != null,
      'Either message or content must be provided',
    );

    final messenger = ScaffoldMessenger.of(this);
    if (clearPrevious) {
      messenger.hideCurrentSnackBar();
    }

    final effectiveTextColor =
        foregroundColor ??
        (backgroundColor != null
            ? (backgroundColor == scheme.error ? scheme.onError : null)
            : null);

    final textWidget =
        content ??
        Text(
          message!,
          style: effectiveTextColor != null
              ? TextStyle(color: effectiveTextColor)
              : null,
        );

    final effectiveIcon =
        iconWidget ??
        (icon != null
            ? Icon(
                icon,
                size: 20,
                color: iconColor ?? effectiveTextColor ?? scheme.inversePrimary,
              )
            : null);

    final effectiveContent = effectiveIcon != null
        ? Row(
            children: [
              effectiveIcon,
              const SizedBox(width: 8),
              Expanded(child: textWidget),
            ],
          )
        : textWidget;

    return messenger.showSnackBar(
      SnackBar(
        content: effectiveContent,
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
        behavior: behavior,
      ),
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    bool clearPrevious = true,
  }) {
    return showSnackBar(
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: scheme.error,
      foregroundColor: scheme.onError,
      duration: duration,
      action: action,
      clearPrevious: clearPrevious,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool clearPrevious = true,
  }) {
    return showSnackBar(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      duration: duration,
      action: action,
      clearPrevious: clearPrevious,
    );
  }
}
