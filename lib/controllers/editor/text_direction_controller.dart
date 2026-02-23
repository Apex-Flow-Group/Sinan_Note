// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/widgets.dart';

import 'package:intl/intl.dart' show Bidi;

/// Model class representing text direction information for a paragraph
class ParagraphDirection {
  final String text;
  final TextDirection direction;
  final int startOffset;
  final int endOffset;
  
  const ParagraphDirection({
    required this.text,
    required this.direction,
    required this.startOffset,
    required this.endOffset,
  });
  
  @override
  String toString() {
    return 'ParagraphDirection(text: "${text.substring(0, text.length > 20 ? 20 : text.length)}...", '
           'direction: $direction, start: $startOffset, end: $endOffset)';
  }
}

/// Controller for handling bidirectional text (RTL/LTR) in the note editor
/// 
/// This controller provides per-paragraph text direction detection for mixed
/// Arabic/English content, ensuring proper rendering and cursor positioning.
/// 
/// **Features:**
/// - Per-paragraph direction detection (not per-note)
/// - Uses Flutter's Bidi class for accurate detection
/// - Handles mixed-language content seamlessly
/// - Maintains cursor position during direction changes
/// 
/// **Best Practices:**
/// - Each paragraph is analyzed independently
/// - RTL characters (Arabic, Hebrew, etc.) trigger RTL direction
/// - LTR characters (English, numbers, etc.) trigger LTR direction
/// - Empty paragraphs default to LTR
/// 
/// **Example:**
/// ```dart
/// final controller = TextDirectionController();
/// final direction = controller.detectParagraphDirection('مرحبا بك');
/// // Returns: TextDirection.rtl
/// 
/// final direction2 = controller.detectParagraphDirection('Hello World');
/// // Returns: TextDirection.ltr
/// ```
class TextDirectionController {
  /// Detect text direction for a single paragraph
  /// 
  /// Uses Flutter's Bidi class which implements the Unicode Bidirectional Algorithm.
  /// This provides accurate detection for all languages and scripts.
  /// 
  /// **Algorithm:**
  /// 1. Trim whitespace from text
  /// 2. If empty, default to LTR
  /// 3. Use Bidi.detectRtlDirectionality() for detection
  /// 4. Return appropriate TextDirection
  /// 
  /// **Parameters:**
  /// - `text`: The paragraph text to analyze
  /// 
  /// **Returns:** TextDirection.rtl for RTL text, TextDirection.ltr otherwise
  /// 
  /// **Examples:**
  /// ```dart
  /// detectParagraphDirection('مرحبا')      // RTL
  /// detectParagraphDirection('Hello')      // LTR
  /// detectParagraphDirection('مرحبا Hello') // RTL (RTL takes precedence)
  /// detectParagraphDirection('')           // LTR (default)
  /// ```
  TextDirection detectParagraphDirection(String text) {
    if (text.trim().isEmpty) return TextDirection.ltr;
    
    // Use Flutter's Bidi class for accurate detection
    // This implements the Unicode Bidirectional Algorithm
    final isRtl = Bidi.detectRtlDirectionality(text);
    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Get text directions for all paragraphs in content
  /// 
  /// Splits content by newlines and detects direction for each paragraph.
  /// This enables per-paragraph rendering with correct text direction.
  /// 
  /// **Flow:**
  /// 1. Split content by '\n' (newline)
  /// 2. For each paragraph:
  ///    - Detect text direction
  ///    - Calculate start/end offsets
  ///    - Create ParagraphDirection object
  /// 3. Return list of ParagraphDirection objects
  /// 
  /// **Parameters:**
  /// - `content`: The full note content (multi-paragraph)
  /// 
  /// **Returns:** List of ParagraphDirection objects, one per paragraph
  /// 
  /// **Example:**
  /// ```dart
  /// final content = 'مرحبا\nHello\nمرحبا مرة أخرى';
  /// final directions = getParagraphDirections(content);
  /// // Returns:
  /// // [
  /// //   ParagraphDirection(text: 'مرحبا', direction: RTL, start: 0, end: 5),
  /// //   ParagraphDirection(text: 'Hello', direction: LTR, start: 6, end: 11),
  /// //   ParagraphDirection(text: 'مرحبا مرة أخرى', direction: RTL, start: 12, end: 26)
  /// // ]
  /// ```
  List<ParagraphDirection> getParagraphDirections(String content) {
    final paragraphs = content.split('\n');
    final directions = <ParagraphDirection>[];
    
    int offset = 0;
    for (final paragraph in paragraphs) {
      final direction = detectParagraphDirection(paragraph);
      directions.add(ParagraphDirection(
        text: paragraph,
        direction: direction,
        startOffset: offset,
        endOffset: offset + paragraph.length,
      ));
      offset += paragraph.length + 1; // +1 for newline character
    }
    
    return directions;
  }
  
  /// Detect overall text direction for entire content
  /// 
  /// This is useful for determining the default direction when creating a new note
  /// or when you need a single direction for the entire content.
  /// 
  /// **Algorithm:**
  /// 1. Count RTL and LTR paragraphs
  /// 2. If more RTL paragraphs, return RTL
  /// 3. Otherwise, return LTR
  /// 
  /// **Parameters:**
  /// - `content`: The full note content
  /// 
  /// **Returns:** TextDirection.rtl if majority is RTL, TextDirection.ltr otherwise
  TextDirection detectOverallDirection(String content) {
    final directions = getParagraphDirections(content);
    
    if (directions.isEmpty) return TextDirection.ltr;
    
    // Count RTL vs LTR paragraphs
    int rtlCount = 0;
    int ltrCount = 0;
    
    for (final dir in directions) {
      if (dir.direction == TextDirection.rtl) {
        rtlCount++;
      } else {
        ltrCount++;
      }
    }
    
    // Majority wins
    return rtlCount > ltrCount ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// Update cursor position when switching between RTL/LTR
  /// 
  /// This method ensures cursor position remains stable when text direction changes.
  /// Currently, it preserves the cursor position as-is, but can be extended for
  /// more sophisticated cursor handling if needed.
  /// 
  /// **Parameters:**
  /// - `selection`: Current text selection/cursor position
  /// - `text`: The text content
  /// - `oldDirection`: Previous text direction
  /// - `newDirection`: New text direction
  /// 
  /// **Returns:** Updated TextSelection (currently unchanged)
  TextSelection updateCursorPosition(
    TextSelection selection,
    String text,
    TextDirection oldDirection,
    TextDirection newDirection,
  ) {
    // Preserve cursor position during direction changes
    // This can be extended for more sophisticated cursor handling if needed
    return selection;
  }
  
  /// Check if text contains RTL characters
  /// 
  /// Quick check to see if text contains any RTL characters without
  /// full bidirectional analysis.
  /// 
  /// **Parameters:**
  /// - `text`: Text to check
  /// 
  /// **Returns:** true if text contains RTL characters
  bool containsRtlCharacters(String text) {
    if (text.isEmpty) return false;
    
    // Check for Arabic, Hebrew, and other RTL Unicode ranges
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      
      // Arabic: U+0600 to U+06FF
      // Hebrew: U+0590 to U+05FF
      // Arabic Supplement: U+0750 to U+077F
      // Arabic Extended-A: U+08A0 to U+08FF
      if ((code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0590 && code <= 0x05FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if text contains LTR characters
  /// 
  /// Quick check to see if text contains any LTR characters.
  /// 
  /// **Parameters:**
  /// - `text`: Text to check
  /// 
  /// **Returns:** true if text contains LTR characters
  bool containsLtrCharacters(String text) {
    if (text.isEmpty) return false;
    
    // Check for Latin, numbers, and common LTR characters
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      
      // Basic Latin: U+0000 to U+007F
      // Latin-1 Supplement: U+0080 to U+00FF
      // Latin Extended-A: U+0100 to U+017F
      // Numbers: U+0030 to U+0039
      if ((code >= 0x0000 && code <= 0x007F) ||
          (code >= 0x0080 && code <= 0x00FF) ||
          (code >= 0x0100 && code <= 0x017F) ||
          (code >= 0x0030 && code <= 0x0039)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if text is mixed (contains both RTL and LTR characters)
  /// 
  /// Useful for determining if special handling is needed for mixed content.
  /// 
  /// **Parameters:**
  /// - `text`: Text to check
  /// 
  /// **Returns:** true if text contains both RTL and LTR characters
  bool isMixedDirection(String text) {
    return containsRtlCharacters(text) && containsLtrCharacters(text);
  }
}
