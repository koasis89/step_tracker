import 'dart:math';
import 'package:flutter/material.dart';

class FlyingObjectAnimation extends StatefulWidget {
  const FlyingObjectAnimation({super.key});

  @override
  State<FlyingObjectAnimation> createState() => _FlyingObjectAnimationState();
}

class _FlyingObjectAnimationState extends State<FlyingObjectAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15), // 비행 속도 조절
      vsync: this,
    )..repeat();

    // 화면 너비를 기준으로 애니메이션 설정
    _animation = Tween<double>(begin: 1.2, end: -0.2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: 10, // 상단에서의 위치
          left: _animation.value * screenWidth,
          child: Transform(
            transform: Matrix4.rotationY(pi), // 이미지를 좌우로 뒤집기
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/airplane.png',
              width: 80, // 이미지 크기
              height: 80,
            ),
          ),
        );
      },
    );
  }
}




