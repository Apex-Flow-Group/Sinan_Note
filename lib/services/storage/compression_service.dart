// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:io';



class CompressionService {
  /// Compress JSON string using GZip (built-in)
  static List<int> compress(String jsonString) {
    final bytes = utf8.encode(jsonString);
    return GZipCodec().encode(bytes);
  }

  /// Decompress GZip bytes to JSON string
  static String decompress(List<int> compressed) {
    final bytes = GZipCodec().decode(compressed);
    return utf8.decode(bytes);
  }
}

