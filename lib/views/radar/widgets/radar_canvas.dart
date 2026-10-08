import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:blue_pulse/core/constants/app_colors.dart';
import 'package:blue_pulse/core/utils/extensions.dart';
import 'package:blue_pulse/core/utils/preview_annotations.dart';
import 'package:blue_pulse/core/utils/signal_math.dart';
import 'package:blue_pulse/data/models/ble_device_model.dart';

/// Radar Canvas Widget visualizing BLE proximity through dynamic concentric rings,
/// animated radar sweep, target blip, and glowing pulse pings.
///
/// Follows the Dumb Component Pattern: receives data via properties and has no service locator calls.
class const RadarCanvas({
  super.key,
  required final BleDeviceModel device,
  required final bool isLost,
}) extends StatefulWidget {
  @override
  State<RadarCanvas> createState() => _RadarCanvasState();
}

class _RadarCanvasState extends State<RadarCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final AnimationController _waveController;
  late final AnimationController _pingController;

  @override
  void initState() {
    super.initState();

    _sweepController = AnimationController(
      vsync: this,
      duration: 4.seconds,
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: 2400.ms,
    )..repeat();

    _pingController = AnimationController(
      vsync: this,
      duration: 700.ms,
    );

    // Initial ping on mount if not lost
    if (!widget.isLost) {
      _pingController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant RadarCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    final receivedNewPacket =
        oldWidget.device.lastSeen != widget.device.lastSeen ||
        oldWidget.device.rawRssi != widget.device.rawRssi;

    if (receivedNewPacket && !widget.isLost) {
      _pingController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _waveController.dispose();
    _pingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final text = context.text;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _sweepController,
        _waveController,
        _pingController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          painter: _RadarPainter(
            sweepAngle: _sweepController.value * 2 * math.pi,
            waveProgress: _waveController.value,
            pingProgress: _pingController.value,
            device: widget.device,
            isLost: widget.isLost,
            primaryColor: scheme.primary,
            surfaceContainerColor: scheme.surfaceContainerHighest,
            outlineVariantColor: scheme.outlineVariant,
            onSurfaceVariantColor: scheme.onSurfaceVariant,
            labelStyle: text.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: .w600,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ) ??
                TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.sweepAngle,
    required this.waveProgress,
    required this.pingProgress,
    required this.device,
    required this.isLost,
    required this.primaryColor,
    required this.surfaceContainerColor,
    required this.outlineVariantColor,
    required this.onSurfaceVariantColor,
    required this.labelStyle,
  });

  final double sweepAngle;
  final double waveProgress;
  final double pingProgress;
  final BleDeviceModel device;
  final bool isLost;
  final Color primaryColor;
  final Color surfaceContainerColor;
  final Color outlineVariantColor;
  final Color onSurfaceVariantColor;
  final TextStyle labelStyle;

  // Concentric ring distance specifications (<1m, 1-3m, 3-10m, 10-20m, >20m)
  static const _ringFractions = [0.20, 0.40, 0.60, 0.80, 1.00];
  static const _ringLabels = ['<1m', '1-3m', '3-10m', '10-20m', '>20m'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (math.min(size.width, size.height) / 2) * 0.86;
    if (maxRadius <= 0) return;

    final effectiveZoneColor = isLost ? AppColors.signalLost : device.zone.color;

    // 1. Radar Circular Background
    final bgPaint = Paint()
      ..color = surfaceContainerColor.withValues(alpha: 0.25)
      ..style = .fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // 2. Crosshair Grid Lines
    final gridPaint = Paint()
      ..color = outlineVariantColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = .stroke;

    // Horizontal & Vertical axes
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      gridPaint,
    );

    // Diagonal subtle guide lines (45 degrees)
    final diagOffset = maxRadius * 0.7071; // cos(45°)
    final diagPaint = Paint()
      ..color = outlineVariantColor.withValues(alpha: 0.18)
      ..strokeWidth = 0.8
      ..style = .stroke;
    canvas.drawLine(
      Offset(center.dx - diagOffset, center.dy - diagOffset),
      Offset(center.dx + diagOffset, center.dy + diagOffset),
      diagPaint,
    );
    canvas.drawLine(
      Offset(center.dx - diagOffset, center.dy + diagOffset),
      Offset(center.dx + diagOffset, center.dy - diagOffset),
      diagPaint,
    );

    // 3. Dynamic Concentric Rings (5 zones)
    final activeRingIndex = _getActiveRingIndex(device.zone);

    for (var i = 0; i < _ringFractions.length; i++) {
      final r = maxRadius * _ringFractions[i];
      final isCurrentZoneRing = !isLost && (i == activeRingIndex);

      if (isLost) {
        // Dashed ring appearance when signal is lost
        _drawDashedCircle(
          canvas,
          center,
          r,
          Paint()
            ..color = AppColors.signalLost.withValues(alpha: 0.3)
            ..strokeWidth = 1.0
            ..style = .stroke,
        );
      } else if (isCurrentZoneRing) {
        // Highlight active zone ring with soft glow
        final glowPaint = Paint()
          ..color = effectiveZoneColor.withValues(alpha: 0.22)
          ..strokeWidth = 4.0
          ..style = .stroke;
        canvas.drawCircle(center, r, glowPaint);

        final activeRingPaint = Paint()
          ..color = effectiveZoneColor.withValues(alpha: 0.85)
          ..strokeWidth = 1.8
          ..style = .stroke;
        canvas.drawCircle(center, r, activeRingPaint);
      } else {
        final ringPaint = Paint()
          ..color = outlineVariantColor.withValues(alpha: 0.45)
          ..strokeWidth = 1.0
          ..style = .stroke;
        canvas.drawCircle(center, r, ringPaint);
      }

      // Draw Distance Range Labels on the vertical top axis
      _drawRingLabel(canvas, center, r, _ringLabels[i]);
    }

    // 4. Concentric Pulsing Wave (Expanding ripple)
    if (!isLost && waveProgress > 0) {
      final waveRadius = maxRadius * waveProgress;
      final waveAlpha = (1.0 - waveProgress) * 0.25;
      final wavePaint = Paint()
        ..color = effectiveZoneColor.withValues(alpha: waveAlpha)
        ..strokeWidth = 1.5
        ..style = .stroke;
      canvas.drawCircle(center, waveRadius, wavePaint);
    }

    // 5. Radar Sweep Beam & Line
    if (!isLost) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi / 2,
          colors: [
            effectiveZoneColor.withValues(alpha: 0.0),
            effectiveZoneColor.withValues(alpha: 0.16),
          ],
          transform: GradientRotation(sweepAngle - (math.pi / 2)),
        ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
        ..style = .fill;
      canvas.drawCircle(center, maxRadius, sweepPaint);

      // Rotating sweep line
      final sweepEnd = center +
          Offset(math.cos(sweepAngle), math.sin(sweepAngle)) * maxRadius;
      final linePaint = Paint()
        ..color = effectiveZoneColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..style = .stroke;
      canvas.drawLine(center, sweepEnd, linePaint);
    }

    // 6. Center Observer Point (Phone / Host User)
    final hostCorePaint = Paint()
      ..color = primaryColor
      ..style = .fill;
    final hostHaloPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.25)
      ..style = .fill;
    canvas.drawCircle(center, 8, hostHaloPaint);
    canvas.drawCircle(center, 4, hostCorePaint);

    // 7. Target Blip Rendering
    _drawTargetBlip(
      canvas: canvas,
      center: center,
      maxRadius: maxRadius,
      zoneColor: effectiveZoneColor,
    );
  }

  void _drawTargetBlip({
    required Canvas canvas,
    required Offset center,
    required double maxRadius,
    required Color zoneColor,
  }) {
    // Deterministic angle based on device ID hash, mapped to upper-front quadrant [-140°, -40°]
    final hash = device.id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final angleDeg = -140.0 + (hash % 101); // -140° to -40°
    final angleRad = angleDeg * (math.pi / 180.0);

    // Compute radial distance fraction
    final radialFraction = _computeRadialFraction(device.estimatedDistance);
    final blipRadius = radialFraction * maxRadius;
    final blipPos = center +
        Offset(math.cos(angleRad) * blipRadius, math.sin(angleRad) * blipRadius);

    if (isLost) {
      // Dashed guide line to center
      _drawDashedLine(
        canvas,
        center,
        blipPos,
        Paint()
          ..color = AppColors.signalLost.withValues(alpha: 0.4)
          ..strokeWidth = 1.0,
      );

      // Faded dashed outer circle
      _drawDashedCircle(
        canvas,
        blipPos,
        12.0,
        Paint()
          ..color = AppColors.signalLost.withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..style = .stroke,
      );

      // Faded inner core
      final lostCorePaint = Paint()
        ..color = AppColors.signalLost.withValues(alpha: 0.5)
        ..style = .fill;
      canvas.drawCircle(blipPos, 5.0, lostCorePaint);

      // Blip Tag "Lost"
      _drawBlipTag(canvas, blipPos, 'Lost', AppColors.signalLost);
    } else {
      // Solid subtle vector guide to center
      final vectorPaint = Paint()
        ..color = zoneColor.withValues(alpha: 0.22)
        ..strokeWidth = 1.0
        ..style = .stroke;
      canvas.drawLine(center, blipPos, vectorPaint);

      // Glowing Pulse Ping when packet received
      if (pingProgress > 0 && pingProgress < 1.0) {
        final pingRadius = 6.0 + (pingProgress * 26.0);
        final pingAlpha = (1.0 - pingProgress) * 0.8;
        final pingPaint = Paint()
          ..color = zoneColor.withValues(alpha: pingAlpha)
          ..strokeWidth = 2.0
          ..style = .stroke;
        canvas.drawCircle(blipPos, pingRadius, pingPaint);
      }

      // Outer glow halo
      final haloPaint = Paint()
        ..color = zoneColor.withValues(alpha: 0.22)
        ..style = .fill;
      canvas.drawCircle(blipPos, 14.0, haloPaint);

      // Mid ring
      final midPaint = Paint()
        ..color = zoneColor.withValues(alpha: 0.45)
        ..style = .fill;
      canvas.drawCircle(blipPos, 8.5, midPaint);

      // Solid target core
      final corePaint = Paint()
        ..color = zoneColor
        ..style = .fill;
      canvas.drawCircle(blipPos, 5.0, corePaint);

      // Distance tag pill
      final distStr = device.estimatedDistance >= 0
          ? '${device.estimatedDistance.toStringAsFixed(1)}m'
          : 'N/A';
      _drawBlipTag(canvas, blipPos, distStr, zoneColor);
    }
  }

  double _computeRadialFraction(double distance) {
    if (distance < 0 || isLost) {
      return 0.92;
    }
    if (distance < 1.0) {
      return (distance / 1.0) * 0.20;
    } else if (distance < 3.0) {
      return 0.20 + (((distance - 1.0) / 2.0) * 0.20);
    } else if (distance < 10.0) {
      return 0.40 + (((distance - 3.0) / 7.0) * 0.20);
    } else if (distance < 20.0) {
      return 0.60 + (((distance - 10.0) / 10.0) * 0.20);
    } else {
      final excess = math.min(30.0, distance - 20.0);
      return 0.80 + ((excess / 30.0) * 0.15);
    }
  }

  int _getActiveRingIndex(ProximityZone zone) {
    return switch (zone) {
      .veryStrong => 0,
      .strong => 1,
      .fair => 2,
      .weak => 3,
      .veryWeak || .lost => 4,
    };
  }

  void _drawRingLabel(
    Canvas canvas,
    Offset center,
    double radius,
    String label,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: .ltr,
    )..layout();

    // Place slightly to the right of vertical axis
    final labelPos = Offset(
      center.dx + 4,
      center.dy - radius - textPainter.height - 2,
    );
    textPainter.paint(canvas, labelPos);
  }

  void _drawBlipTag(
    Canvas canvas,
    Offset blipPos,
    String text,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: .ltr,
    )..layout();

    const hPad = 6.0;
    const vPad = 2.0;
    final tagRect = Rect.fromCenter(
      center: Offset(blipPos.dx, blipPos.dy - 18.0),
      width: tp.width + (hPad * 2),
      height: tp.height + (vPad * 2),
    );

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = .fill;
    final rrect = RRect.fromRectAndRadius(tagRect, const Radius.circular(4));
    canvas.drawRRect(rrect, bgPaint);

    tp.paint(
      canvas,
      Offset(tagRect.left + hPad, tagRect.top + vPad),
    );
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashLength = 4.0;
    const gapLength = 4.0;
    final circumference = 2 * math.pi * radius;
    final totalSteps = (circumference / (dashLength + gapLength)).floor();
    if (totalSteps <= 0) return;

    final angleStep = (2 * math.pi) / totalSteps;
    final dashAngle = angleStep * (dashLength / (dashLength + gapLength));

    for (var i = 0; i < totalSteps; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset p1,
    Offset p2,
    Paint paint,
  ) {
    const dashLength = 4.0;
    const gapLength = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0) return;

    final steps = (dist / (dashLength + gapLength)).floor();
    final unitX = dx / dist;
    final unitY = dy / dist;

    var curX = p1.dx;
    var curY = p1.dy;

    for (var i = 0; i < steps; i++) {
      final nextX = curX + (unitX * dashLength);
      final nextY = curY + (unitY * dashLength);
      canvas.drawLine(Offset(curX, curY), Offset(nextX, nextY), paint);
      curX = nextX + (unitX * gapLength);
      curY = nextY + (unitY * gapLength);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.waveProgress != waveProgress ||
        oldDelegate.pingProgress != pingProgress ||
        oldDelegate.device != device ||
        oldDelegate.isLost != isLost;
  }
}

@BluePulsePreview(name: 'Radar Canvas')
Widget previewRadarCanvas() {
  return SizedBox.square(
    dimension: 340,
    child: RadarCanvas(
      device: .new(
        id: 'AA:BB:CC:DD:EE:FF',
        name: 'Pulse Tracker Pro',
        rawRssi: -58,
        smoothedRssi: -57.4,
        estimatedDistance: 2.1,
        zone: .strong,
        lastSeen: .now(),
      ),
      isLost: false,
    ),
  );
}
