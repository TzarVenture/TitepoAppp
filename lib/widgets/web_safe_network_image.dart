import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Drop-in replacement for [CachedNetworkImage].
///
/// On Android/iOS it uses [CachedNetworkImage] (disk cache).
/// On the web it uses [Image.network]: cached_network_image's web cache can
/// fail to reload images after navigating back (all images then show the
/// error widget). The browser's own HTTP cache already caches the images.
class WebSafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Duration fadeInDuration;
  final Widget Function(BuildContext context, String url)? placeholder;
  final Widget Function(BuildContext context, String url, Object error)? errorWidget;

  const WebSafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        fadeInDuration: fadeInDuration,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) return child;
        return placeholder?.call(context, imageUrl) ?? SizedBox(width: width, height: height);
      },
      errorBuilder: (context, error, _) =>
          errorWidget?.call(context, imageUrl, error) ?? SizedBox(width: width, height: height),
    );
  }
}
