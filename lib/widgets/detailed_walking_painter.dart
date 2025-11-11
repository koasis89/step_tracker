
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Helper to interpolate between values
double lerp(double min, double max, double t) {
  return min + (max - min) * t;
}

class DetailedWalkingPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDarkMode;

  DetailedWalkingPainter({required this.animation, required this.isDarkMode}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // 테마에 따라 색상 결정
    final bodyColor = isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF000080);

    final paint = Paint()
      // 선 색상을 Colors.white로 변경
      //..color = Colors.white
      ..color = bodyColor
      ..strokeWidth = 4.0 
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final headRadius = size.width / 10;
    
    final headBottomY = centerY - headRadius * 1.5;
    final bodyTop = Offset(centerX, headBottomY);
    final bodyBottom = Offset(centerX, centerY + headRadius * 1.5);

    // 머리 그리기
    canvas.drawCircle(Offset(centerX, centerY - headRadius * 2.5), headRadius, paint);
    // 몸통 그리기
    canvas.drawLine(bodyTop, bodyBottom, paint);

    // Limb lengths
    final upperArmLength = headRadius * 1.5;
    final lowerArmLength = headRadius * 1.3;
    final thighLength = headRadius * 1.6;
    final calfLength = headRadius * 1.5;

    // Joint positions
    final hip = bodyBottom;
    final shoulder = Offset(centerX, headBottomY + headRadius * 0.3);

    // Animation phase (0.0 to 1.0)
    final phase = animation.value;

    // t goes from 0 -> 1 -> 0 as phase goes from 0 -> 0.5 -> 1
    final t = 1.0 - (2 * phase - 1).abs(); 

    // Leg angles (swinging)
    final maxThighAngle = math.pi / 5; // Max angle for thighs
    final rightThighAngle = lerp(-maxThighAngle, maxThighAngle, phase);
    final leftThighAngle = lerp(maxThighAngle, -maxThighAngle, phase);

    // Arm angles (opposite to legs)
    final maxArmAngle = math.pi / 6;
    final rightUpperArmAngle = lerp(maxArmAngle, -maxArmAngle, phase);
    final leftUpperArmAngle = lerp(-maxArmAngle, maxArmAngle, phase);

    // Bending angles for knees and elbows
    final maxKneeBend = math.pi / 4;
    final rightKneeBend = lerp(0, maxKneeBend, t);
    final leftKneeBend = lerp(maxKneeBend, 0, t);
    
    final maxElbowBend = math.pi / 5;
    final rightElbowBend = lerp(maxElbowBend, 0, t);
    final leftElbowBend = lerp(0, maxElbowBend, t);
    
    // Function to draw a limb with a joint
    void drawLimb(Offset joint, double angle1, double length1, double bendAngle, double length2) {
      final midJoint = Offset(
        joint.dx + length1 * math.sin(angle1),
        joint.dy + length1 * math.cos(angle1),
      );
      canvas.drawLine(joint, midJoint, paint);

      final angle2 = angle1 + bendAngle; // Add bend angle
      final endPoint = Offset(
        midJoint.dx + length2 * math.sin(angle2),
        midJoint.dy + length2 * math.cos(angle2),
      );
      canvas.drawLine(midJoint, endPoint, paint);
    }

    // Draw back limbs first for correct layering
    drawLimb(hip, leftThighAngle, thighLength, -leftKneeBend, calfLength);
    drawLimb(shoulder, leftUpperArmAngle, upperArmLength, leftElbowBend, lowerArmLength);
    
    // Draw front limbs
    drawLimb(hip, rightThighAngle, thighLength, -rightKneeBend, calfLength);
    drawLimb(shoulder, rightUpperArmAngle, upperArmLength, rightElbowBend, lowerArmLength);
  }

  @override
  bool shouldRepaint(covariant DetailedWalkingPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.isDarkMode != isDarkMode;
  }
}
