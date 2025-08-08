import 'package:flutter/material.dart';

class MasterGalleryCarousel extends StatelessWidget {
  final List<String> images;
  const MasterGalleryCarousel({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Image.network(images[index]),
          );
        },
      ),
    );
  }
}
