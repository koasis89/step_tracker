
import 'dart:math' as math;
import 'package:flutter/material.dart';

class WalkingManPainter extends CustomPainter {
  final Animation<double> animation;

  WalkingManPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Head
    final headRadius = size.width / 8;
    canvas.drawCircle(Offset(centerX, centerY - headRadius * 2.5), headRadius, paint);

    // Body
    final bodyTop = Offset(centerX, centerY - headRadius * 1.5);
    final bodyBottom = Offset(centerX, centerY + headRadius * 1.5);
    canvas.drawLine(bodyTop, bodyBottom, paint);

    // Animate the angle from -30 degrees to +30 degrees and back.
    final maxAngle = math.pi / 6; // 30 degrees
    final angle = (animation.value * 2.0 - 1.0) * maxAngle;

    final legLength = headRadius * 2.5;
    final armLength = headRadius * 2.0;

    // Joint positions
    final hip = bodyBottom;
    final shoulder = Offset(centerX, centerY - headRadius * 0.5);

    // Right Leg
    final rightLegEnd = Offset(
      hip.dx + math.sin(angle) * legLength,
      hip.dy + math.cos(angle) * legLength,
    );
    canvas.drawLine(hip, rightLegEnd, paint);

    // Left Leg
    final leftLegEnd = Offset(
      hip.dx + math.sin(-angle) * legLength, 
      hip.dy + math.cos(-angle) * legLength,
    );
    canvas.drawLine(hip, leftLegEnd, paint);

    // Left Arm
    final leftArmEnd = Offset(
      shoulder.dx + math.sin(angle) * armLength,
      shoulder.dy + math.cos(angle) * armLength * 0.5, 
    );
    canvas.drawLine(shoulder, leftArmEnd, paint);

    // Right Arm
    final rightArmEnd = Offset(
      shoulder.dx + math.sin(-angle) * armLength,
      shoulder.dy + math.cos(-angle) * armLength * 0.5,
    );
    canvas.drawLine(shoulder, rightArmEnd, paint);
  }

  @override
  bool shouldRepaint(covariant WalkingManPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
