// Unit Test for Memory Leaks
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Memory Leak Tests', () {
    test('TextEditingController disposal', () {
      final controller = TextEditingController();
      expect(() => controller.dispose(), returnsNormally);
    });

    test('FocusNode disposal', () {
      final node = FocusNode();
      expect(() => node.dispose(), returnsNormally);
    });

    test('Multiple controllers disposal', () {
      final controllers = List.generate(100, (_) => TextEditingController());
      expect(() {
        for (var c in controllers) {
          c.dispose();
        }
      }, returnsNormally);
    });
  });
}
