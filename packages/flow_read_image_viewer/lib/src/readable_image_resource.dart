import 'dart:typed_data';

enum ReadableImageSourceType { memory, network }

class ReadableImageResource {
  final ReadableImageSourceType type;
  final Uint8List? bytes;
  final Uri? uri;
  final String? source;
  final String? alt;
  final String? suggestedFileName;
  final double? width;
  final double? height;

  const ReadableImageResource.memory(
    Uint8List this.bytes, {
    this.source,
    this.alt,
    this.suggestedFileName,
    this.width,
    this.height,
  }) : type = ReadableImageSourceType.memory,
       uri = null;

  const ReadableImageResource.network(
    Uri this.uri, {
    this.alt,
    this.suggestedFileName,
    this.width,
    this.height,
  }) : type = ReadableImageSourceType.network,
       bytes = null,
       source = null;

  bool get isMemory => type == ReadableImageSourceType.memory;

  double? get aspectRatio {
    final imageWidth = width;
    final imageHeight = height;
    if (imageWidth == null || imageHeight == null || imageHeight <= 0) {
      return null;
    }
    return (imageWidth / imageHeight).clamp(0.05, 20.0).toDouble();
  }

  String get displaySource => source ?? uri?.toString() ?? '';
}
