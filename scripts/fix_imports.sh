#!/bin/bash
# Copyright © 2025 Apex Flow Group. All rights reserved.
# Professional Import Fixer Runner

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "🚀 Sinan Note - Import Fixer Runner"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

show_help() {
    echo "Usage: ./scripts/fix_imports.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run       Preview changes without applying them"
    echo "  --verbose, -v   Show detailed output"
    echo "  --report        Generate JSON report"
    echo "  --path PATH     Target directory (default: lib)"
    echo "  --test          Fix test files"
    echo "  --all           Fix lib + test + integration_test"
    echo "  --help, -h      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/fix_imports.sh                    # Fix lib/ directory"
    echo "  ./scripts/fix_imports.sh --dry-run          # Preview changes"
    echo "  ./scripts/fix_imports.sh --all --report     # Fix all + report"
    echo "  ./scripts/fix_imports.sh --path lib/models  # Fix specific folder"
    echo ""
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$*" == *"--all"* ]]; then
    echo "📦 Fixing all directories..."
    echo ""
    
    echo "1️⃣  Fixing lib/..."
    dart scripts/fix_imports.dart --path lib "$@"
    echo ""
    
    echo "2️⃣  Fixing test/..."
    dart scripts/fix_imports.dart --path test "$@"
    echo ""
    
    echo "3️⃣  Fixing integration_test/..."
    dart scripts/fix_imports.dart --path integration_test "$@"
    echo ""
    
    echo "✅ All directories fixed!"
elif [[ "$*" == *"--test"* ]]; then
    echo "🧪 Fixing test files..."
    dart scripts/fix_imports.dart --path test "$@"
else
    dart scripts/fix_imports.dart "$@"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ Done! Run 'flutter analyze' to verify."
