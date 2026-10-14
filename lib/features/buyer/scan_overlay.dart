import 'package:flutter/material.dart';

/// Modern squared scanner overlay (Phase 6 fix pack): dimmed surroundings,
/// a rounded-square viewfinder window, gold corner brackets, and a slowly
/// sweeping scan line. Pure decoration over the camera preview.
class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key});
  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (context, _) => CustomPaint(
          painter: _ViewfinderPainter(_anim.value),
          size: Size.infinite,
        ),
      );
}

class _ViewfinderPainter extends CustomPainter {
  _ViewfinderPainter(this.lineT);
  final double lineT;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.72;
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2 - 24;
    final rect = Rect.fromLTWH(left, top, side, side);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Dim everything outside the window.
    final scrim = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    // Window border.
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withValues(alpha: 0.9));

    // Gold corner brackets.
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC5A04D);
    const len = 34.0;
    const r = 24.0;
    final paths = <Path>[
      Path()
        ..moveTo(rect.left, rect.top + r + len)
        ..lineTo(rect.left, rect.top + r)
        ..arcToPoint(Offset(rect.left + r, rect.top),
            radius: const Radius.circular(r))
        ..lineTo(rect.left + r + len, rect.top),
      Path()
        ..moveTo(rect.right - r - len, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..arcToPoint(Offset(rect.right, rect.top + r),
            radius: const Radius.circular(r))
        ..lineTo(rect.right, rect.top + r + len),
      Path()
        ..moveTo(rect.right, rect.bottom - r - len)
        ..lineTo(rect.right, rect.bottom - r)
        ..arcToPoint(Offset(rect.right - r, rect.bottom),
            radius: const Radius.circular(r))
        ..lineTo(rect.right - r - len, rect.bottom),
      Path()
        ..moveTo(rect.left + r + len, rect.bottom)
        ..lineTo(rect.left + r, rect.bottom)
        ..arcToPoint(Offset(rect.left, rect.bottom - r),
            radius: const Radius.circular(r))
        ..lineTo(rect.left, rect.bottom - r - len),
    ];
    for (final p in paths) {
      canvas.drawPath(p, corner);
    }

    // Sweeping scan line inside the window.
    final y = rect.top + 14 + (rect.height - 28) * lineT;
    final lineRect = Rect.fromLTWH(rect.left + 14, y, rect.width - 28, 3);
    canvas.drawRRect(
        RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
        Paint()..color = const Color(0xFFC5A04D).withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => old.lineT != lineT;
}
