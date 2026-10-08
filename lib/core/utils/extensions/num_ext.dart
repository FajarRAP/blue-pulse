import 'package:material_ui/material_ui.dart';

/// Ergonomic UI extensions on [num] for EdgeInsets padding generators.
extension NumX on num {
  /// Generates [EdgeInsets.all] with this numerical value.
  EdgeInsets get allPadding => .all(toDouble());

  /// Generates [EdgeInsets.symmetric] with this horizontal padding.
  EdgeInsets get hPadding => .symmetric(horizontal: toDouble());

  /// Generates [EdgeInsets.symmetric] with this vertical padding.
  EdgeInsets get vPadding => .symmetric(vertical: toDouble());

  /// Generates [EdgeInsets.only] with this left padding.
  EdgeInsets get lPadding => .only(left: toDouble());

  /// Generates [EdgeInsets.only] with this top padding.
  EdgeInsets get tPadding => .only(top: toDouble());

  /// Generates [EdgeInsets.only] with this right padding.
  EdgeInsets get rPadding => .only(right: toDouble());

  /// Generates [EdgeInsets.only] with this bottom padding.
  EdgeInsets get bPadding => .only(bottom: toDouble());

  /// Generates [SizedBox] with this width value.
  Widget get wGap => SizedBox(width: toDouble());

  /// Generates [SizedBox] with this height value.
  Widget get hGap => SizedBox(height: toDouble());

  /// Generates [SliverToBoxAdapter] with this height value.
  Widget get sliverHGap =>
      SliverToBoxAdapter(child: SizedBox(height: toDouble()));

  /// Generates [SliverToBoxAdapter] with this width value.
  Widget get sliverWGap =>
      SliverToBoxAdapter(child: SizedBox(width: toDouble()));
}
