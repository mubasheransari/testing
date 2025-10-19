// models/named_bytes.dart (or alongside your repo)
import 'dart:typed_data';

class NamedBytes {
  final String fileName;
  final Uint8List bytes;
  final String? mimeType; // e.g. 'image/png', 'application/pdf'
  const NamedBytes({
    required this.fileName,
    required this.bytes,
    this.mimeType,
  });
}
