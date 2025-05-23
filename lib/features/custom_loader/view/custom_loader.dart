import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  final double? size;
  final Color? color;

  const CustomLoader({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ShaderMask(
        shaderCallback: (bounds) => material.LinearGradient(
          colors: [color ?? Colors.white, color ?? Colors.white],
          stops: const [0.0, 1.0],
        ).createShader(bounds),
        child: SizedBox(
          width: size ?? 60,
          height: size ?? 60,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
