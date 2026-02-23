// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Service for compressing and decompressing data for Google Drive sync
class CompressionService {
  
  /// Compress JSON data to ZIP format
  /// Returns compressed bytes
  static Uint8List compressJson(Map<String, dynamic> jsonData) {
    // Convert JSON to string
    final jsonString = jsonEncode(jsonData);
    final jsonBytes = utf8.encode(jsonString);
    
    // Create archive
    final archive = Archive();
    
    // Add file to archive
    final file = ArchiveFile(
      'sinan_backup.json',
      jsonBytes.length,
      jsonBytes,
    );
    archive.addFile(file);
    
    // Encode to ZIP
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    
    return Uint8List.fromList(zipBytes!);
  }
  
  /// Decompress ZIP data to JSON
  /// Returns JSON map
  static Map<String, dynamic> decompressToJson(Uint8List zipBytes) {
    // Decode ZIP
    final archive = ZipDecoder().decodeBytes(zipBytes);
    
    // Get first file (should be sinan_backup.json)
    if (archive.isEmpty) {
      throw Exception('Empty archive');
    }
    
    final file = archive.first;
    final jsonBytes = file.content as List<int>;
    
    // Convert to JSON
    final jsonString = utf8.decode(jsonBytes);
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return jsonData;
  }
  
  /// Calculate compression ratio
  static double getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0;
    return ((originalSize - compressedSize) / originalSize) * 100;
  }
  
  /// Format size in human-readable format
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
