import 'package:flutter/material.dart';

class CircleOption extends StatelessWidget {
  final double size;
  final Color color;
  final String label;

  const CircleOption({
    super.key,
    required this.size,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'NauryzKeds', // заменили Lepka на NauryzKeds
          ),
        ),
      ),
    );
  }
}
