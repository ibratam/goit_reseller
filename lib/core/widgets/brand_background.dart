import 'package:flutter/material.dart';

class AppBranding {
  static const String logoAsset = 'assets/images/gowifi_logo.png';
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.width = 180,
    super.key,
  });

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppBranding.logoAsset,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class BrandedBackground extends StatelessWidget {
  const BrandedBackground({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFD),
            Color(0xFFEAF2FB),
            Color(0xFFF6F9FD),
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -10,
            right: -84,
            child: IgnorePointer(
              child: _BackgroundLogoCard(
                width: 250,
                angle: -0.1,
                opacity: 0.24,
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            left: -72,
            child: IgnorePointer(
              child: _BackgroundLogoCard(
                width: 210,
                angle: 0.08,
                opacity: 0.16,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BackgroundLogoCard extends StatelessWidget {
  const _BackgroundLogoCard({
    required this.width,
    required this.angle,
    required this.opacity,
  });

  final double width;
  final double angle;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFD7E3F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 28,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: BrandLogo(width: width),
        ),
      ),
    );
  }
}
