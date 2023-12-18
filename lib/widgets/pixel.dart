import 'package:flutter/material.dart';

class Pixel extends StatelessWidget {
  final Color? color;

  const Pixel({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: color,
      ),
    );
  }
}
