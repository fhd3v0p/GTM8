import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Виджет для отображения изображений с кэшированием
class CachedImageWidget extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? cacheTimeout;

  const CachedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.cacheTimeout,
  }) : super(key: key);

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  /// Генерирует уникальное имя файла для кэша на основе URL
  String _getCacheFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Получает путь к директории кэша
  Future<Directory> _getCacheDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Проверяет, есть ли файл в кэше и не устарел ли он
  Future<File?> _getCachedFile() async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getCacheFileName(widget.imageUrl);
      final file = File('${cacheDir.path}/$fileName');
      
      if (await file.exists()) {
        final stat = await file.stat();
        final cacheTimeout = widget.cacheTimeout ?? const Duration(days: 7);
        
        if (DateTime.now().difference(stat.modified) < cacheTimeout) {
          return file;
        } else {
          // Файл устарел, удаляем его
          await file.delete();
        }
      }
    } catch (e) {
      print('DEBUG: Ошибка проверки кэша: $e');
    }
    
    return null;
  }

  /// Сохраняет изображение в кэш
  Future<void> _saveToCache(Uint8List data) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getCacheFileName(widget.imageUrl);
      final file = File('${cacheDir.path}/$fileName');
      await file.writeAsBytes(data);
    } catch (e) {
      print('DEBUG: Ошибка сохранения в кэш: $e');
    }
  }

  /// Загружает изображение из сети
  Future<Uint8List?> _downloadImage() async {
    try {
      // Преобразуем локальные пути в полные URL
      String fullUrl = widget.imageUrl;
      
      if (widget.imageUrl.startsWith('assets/')) {
        // Локальный ассет - загружаем через AssetBundle
        try {
          final bundle = DefaultAssetBundle.of(context);
          final data = await bundle.load(widget.imageUrl);
          return data.buffer.asUint8List();
        } catch (e) {
          print('DEBUG: Ошибка загрузки ассета ${widget.imageUrl}: $e');
          return null;
        }
      } else if (!widget.imageUrl.startsWith('http')) {
        // Относительный путь - преобразуем в полный URL
        fullUrl = '${ApiConfig.supabaseUrl}/storage/v1/object/public/${ApiConfig.storageBucket}/${widget.imageUrl}';
      }
      
      final response = await http.get(Uri.parse(fullUrl), headers: {
        'User-Agent': 'GTM-Flutter-App/1.0',
      });
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('DEBUG: HTTP ${response.statusCode} для $fullUrl');
        return null;
      }
    } catch (e) {
      print('DEBUG: Ошибка загрузки изображения: $e');
      return null;
    }
  }

  /// Загружает изображение (из кэша или сети)
  Future<void> _loadImage() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Сначала пытаемся загрузить из кэша
      final cachedFile = await _getCachedFile();
      if (cachedFile != null) {
        final data = await cachedFile.readAsBytes();
        if (mounted) {
          setState(() {
            _imageData = data;
            _isLoading = false;
          });
        }
        return;
      }

      // Если нет в кэше, загружаем из сети
      final data = await _downloadImage();
      if (data != null) {
        // Сохраняем в кэш
        await _saveToCache(data);
        
        if (mounted) {
          setState(() {
            _imageData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      print('DEBUG: Ошибка в _loadImage: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        child: widget.placeholder ?? 
          const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ),
      );
    }

    if (_hasError || _imageData == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.errorWidget ?? 
          const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 24,
            ),
          ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        _imageData!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Утилиты для управления кэшем изображений
class ImageCacheManager {
  static const String _cacheDirectory = 'image_cache';
  
  /// Очищает весь кэш изображений
  static Future<void> clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_cacheDirectory');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('DEBUG: Кэш изображений очищен');
      }
    } catch (e) {
      print('DEBUG: Ошибка очистки кэша: $e');
    }
  }
  
  /// Получает размер кэша в байтах
  static Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_cacheDirectory');
      
      if (!await cacheDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      print('DEBUG: Ошибка получения размера кэша: $e');
      return 0;
    }
  }
  
  /// Очищает устаревшие файлы из кэша
  static Future<void> cleanExpiredCache({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/$_cacheDirectory');
      
      if (!await cacheDir.exists()) {
        return;
      }
      
      final now = DateTime.now();
      int deletedCount = 0;
      
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > maxAge) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      
      print('DEBUG: Удалено $deletedCount устаревших файлов из кэша');
    } catch (e) {
      print('DEBUG: Ошибка очистки устаревшего кэша: $e');
    }
  }
}