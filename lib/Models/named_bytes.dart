import 'dart:typed_data';

class NamedBytes {
  final Uint8List bytes;
  final String fileName;
  final String? mimeType;
  const NamedBytes({
    required this.bytes,
    required this.fileName,
    this.mimeType,
  });
}
