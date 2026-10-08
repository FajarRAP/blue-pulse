import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';

final class const BluePulsePreview({
  super.name,
  super.group,
  super.size,
  super.textScaleFactor,
  super.wrapper,
  super.brightness,
  super.localizations,
  final EdgeInsets padding = const .all(16),
}) extends Preview {
  this : super(theme: PreviewMaterialThemeData.new);
  @override
  Preview transform() {
    final originalPreview = super.transform();
    final builder = originalPreview.toBuilder();
    builder.wrapper = (preview) => MaterialApp(
      home: Scaffold(
        body: Padding(padding: padding, child: preview),
      ),
    );

    return builder.build();
  }
}

final class const PreviewMaterialThemeData() extends PreviewThemeData {
  @override
  Widget apply(BuildContext context, Widget child) => Theme(
    data: .from(colorScheme: .fromSeed(seedColor: AppColors.primarySeed)),
    child: child,
  );
}
