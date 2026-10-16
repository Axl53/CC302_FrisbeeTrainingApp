import 'package:flutter/material.dart';

// Shared asset treatment for the whole-disc hero and cropped card thumbnails.
class DiscPhoto extends StatelessWidget {
  const DiscPhoto(
      {super.key,
      required this.width,
      required this.height,
      this.fit = BoxFit.cover,
      this.radius = 16});

  final double width;
  final double height;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
            width: width,
            height: height,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Image.asset(
                'assets/images/frisbee_disc.jpg',
                width: width,
                height: height,
                fit: fit,
                alignment: fit == BoxFit.cover
                    ? const Alignment(0.2, 0)
                    : Alignment.center,
                semanticLabel: 'Frisbee disc',
                errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                  Icons.sports,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  semanticLabel: 'Frisbee photo unavailable',
                )),
              ),
            )),
      );
}
