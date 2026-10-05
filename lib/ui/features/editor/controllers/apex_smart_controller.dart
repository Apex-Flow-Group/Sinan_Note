// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';

/// ApexSmartController - Text controller with stability-first approach
///
/// Markdown parsing has been DISABLED to ensure RTL/LTR cursor stability.
/// The controller now uses Flutter's default text rendering (raw text display).
class ApexSmartController extends TextEditingController {
  ApexSmartController({super.text});

  // ============================================================================
  // MARKDOWN PARSING DISABLED (Stability First Strategy)
  // ============================================================================
  // The buildTextSpan override has been removed to fix RTL cursor issues.
  // Text is now displayed exactly as typed (e.g., **text** shows as **text**).
  // This ensures 100% cursor stability in mixed RTL/LTR content.
  // ============================================================================

  // Future: Add utility methods here if needed for text analysis
  // (without affecting visual rendering)
}
