import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CasandesLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const CasandesLogo({
    super.key,
    this.width = 180,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/casandes_logo.svg',
      width: width,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
