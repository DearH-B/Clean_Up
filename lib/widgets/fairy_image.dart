import 'package:flutter/material.dart';

class FairyImage extends StatelessWidget {
  const FairyImage({
    this.size = 96,
    this.assetPath = '캐릭터/귀여운 분홍새.png',
    super.key,
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
