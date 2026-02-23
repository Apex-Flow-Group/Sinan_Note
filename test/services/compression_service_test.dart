// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/services/storage/compression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompressionService Tests', () {
    test('compressJson should return non-empty bytes', () {
      final data = {
        'notes': [
          {'id': 1, 'title': 'Test', 'content': 'Hello World'},
        ],
        'version': '2.1.1',
      };

      final compressed = CompressionService.compressJson(data);

      expect(compressed, isNotEmpty);
      expect(compressed.length, greaterThan(0));
    });

    test('decompressToJson should restore original data', () {
      final originalData = {
        'notes': [
          {'id': 1, 'title': 'Test Note', 'content': 'This is a test'},
          {'id': 2, 'title': 'Another', 'content': 'More content here'},
        ],
        'settings': {'theme': 'dark', 'language': 'en'},
        'version': '2.1.1',
      };

      final compressed = CompressionService.compressJson(originalData);
      final decompressed = CompressionService.decompressToJson(compressed);

      expect(decompressed, equals(originalData));
    });

    test('compression should reduce size for large data', () {
      // Create large dataset
      final largeData = {
        'notes': List.generate(
            100,
            (i) => {
                  'id': i,
                  'title': 'Note $i',
                  'content': 'This is a long content for note $i. ' * 10,
                  'createdAt': DateTime.now().toIso8601String(),
                }),
      };

      final compressed = CompressionService.compressJson(largeData);
      final originalSize = largeData.toString().length;
      final compressedSize = compressed.length;

      expect(compressedSize, lessThan(originalSize));

      final ratio =
          CompressionService.getCompressionRatio(originalSize, compressedSize);
      expect(ratio, greaterThan(0));
    });

    test('formatSize should format bytes correctly', () {
      expect(CompressionService.formatSize(500), equals('500 B'));
      expect(CompressionService.formatSize(1024), equals('1.0 KB'));
      expect(CompressionService.formatSize(1536), equals('1.5 KB'));
      expect(CompressionService.formatSize(1024 * 1024), equals('1.0 MB'));
      expect(CompressionService.formatSize(1024 * 1024 * 2), equals('2.0 MB'));
    });

    test('should handle empty data', () {
      final emptyData = <String, dynamic>{};

      final compressed = CompressionService.compressJson(emptyData);
      final decompressed = CompressionService.decompressToJson(compressed);

      expect(decompressed, equals(emptyData));
    });

    test('should handle nested data structures', () {
      final complexData = {
        'level1': {
          'level2': {
            'level3': {
              'data': [1, 2, 3, 4, 5],
              'text': 'Deep nesting test',
            }
          }
        }
      };

      final compressed = CompressionService.compressJson(complexData);
      final decompressed = CompressionService.decompressToJson(compressed);

      expect(decompressed, equals(complexData));
    });

    test('should handle special characters', () {
      final dataWithSpecialChars = {
        'arabic': 'مرحباً بك في سنان نوت',
        'emoji': '🔐 🚀 ✅',
        'symbols': '!@#\$%^&*()',
      };

      final compressed = CompressionService.compressJson(dataWithSpecialChars);
      final decompressed = CompressionService.decompressToJson(compressed);

      expect(decompressed, equals(dataWithSpecialChars));
    });
  });
}
