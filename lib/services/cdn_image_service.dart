import 'package:flutter/material.dart';
import '../config/api_config.dart';

class CdnImageService {
  static String get baseUrl => ApiConfig.supabaseUrl;
  static String get bucket => ApiConfig.storageBucket;
  
  /// Получение URL изображения из Supabase Storage
  static String getImageUrl(String path, {String? artistId}) {
    if (path.startsWith('http')) {
      return path; // Уже полный URL
    }
    
    if (path.startsWith('assets/')) {
      return path; // Локальный ассет
    }
    
    // Формируем URL для Supabase Storage
    return '$baseUrl/storage/v1/object/public/$bucket/$path';
  }
  
  /// Получение URL аватара артиста
  static String getArtistAvatarUrl(String artistId) {
    return getImageUrl('artists/$artistId/avatar.png');
  }
  
  /// Получение URL изображения галереи артиста
  static String getArtistGalleryImageUrl(String artistId, int imageNumber) {
    return getImageUrl('artists/$artistId/gallery$imageNumber.jpg');
  }
  
  /// Получение списка URL изображений галереи артиста
  static List<String> getArtistGalleryUrls(String artistId, {int maxImages = 10}) {
    final urls = <String>[];
    for (int i = 1; i <= maxImages; i++) {
      urls.add(getArtistGalleryImageUrl(artistId, i));
    }
    return urls;
  }
  
  /// Получение URL баннера
  static String getBannerUrl(String bannerName) {
    return getImageUrl('banners/$bannerName');
  }
  
  /// Получение URL продукта
  static String getProductImageUrl(String productId, {String? imageName}) {
    if (imageName != null) {
      return getImageUrl('products/$productId/$imageName');
    }
    return getImageUrl('products/$productId/main.jpg');
  }
  
  /// Получение URL аватара по умолчанию
  static String getDefaultAvatarUrl(int avatarNumber) {
    return getImageUrl('avatars/avatar$avatarNumber.png');
  }
}

/// Виджет для отображения изображений с CDN
class CdnImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const CdnImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final processedUrl = CdnImageService.getImageUrl(imageUrl);
    
    Widget imageWidget;
    
    if (processedUrl.startsWith('assets/')) {
      // Локальный ассет
      imageWidget = Image.asset(
        processedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    } else {
      // Сетевой URL
      imageWidget = Image.network(
        processedUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    }
    
    // Применяем стили
    Widget result = imageWidget;
    
    if (borderRadius != null) {
      result = ClipRRect(
        borderRadius: borderRadius!,
        child: result,
      );
    }
    
    if (border != null) {
      result = Container(
        decoration: BoxDecoration(border: border),
        child: result,
      );
    }
    
    return result;
  }
}

/// Виджет для отображения аватара артиста
class ArtistAvatar extends StatelessWidget {
  final String artistId;
  final double? size;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const ArtistAvatar({
    super.key,
    required this.artistId,
    this.size,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = CdnImageService.getArtistAvatarUrl(artistId);
    
    return CdnImage(
      imageUrl: avatarUrl,
      width: size,
      height: size,
      fit: fit ?? BoxFit.cover,
      placeholder: placeholder,
      errorWidget: errorWidget ?? const Icon(Icons.person),
      borderRadius: borderRadius ?? BorderRadius.circular(size != null ? size! / 2 : 20),
    );
  }
}

/// Виджет для отображения галереи артиста
class ArtistGallery extends StatelessWidget {
  final String artistId;
  final int maxImages;
  final double? itemWidth;
  final double? itemHeight;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const ArtistGallery({
    super.key,
    required this.artistId,
    this.maxImages = 10,
    this.itemWidth,
    this.itemHeight,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final galleryUrls = CdnImageService.getArtistGalleryUrls(artistId, maxImages: maxImages);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: galleryUrls.length,
      itemBuilder: (context, index) {
        return CdnImage(
          imageUrl: galleryUrls[index],
          width: itemWidth,
          height: itemHeight,
          fit: fit ?? BoxFit.cover,
          placeholder: placeholder,
          errorWidget: errorWidget,
          borderRadius: borderRadius,
        );
      },
    );
  }
} 