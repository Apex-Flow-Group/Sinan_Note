#!/usr/bin/env python3
"""
Sinan Note Build Script
Automatically increments version code and builds the app
"""

import re
import subprocess
import sys
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# 1. قراءة ملف pubspec.yaml
file_path = 'pubspec.yaml'
try:
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
except FileNotFoundError:
    logger.error("❌ Error: pubspec.yaml not found!")
    sys.exit(1)

# 2. البحث عن رقم النسخة وزيادته
# يبحث عن النمط: version: x.y.z+number
pattern = r'(version: .*\+)(\d+)'

def increment_version(match):
    prefix = match.group(1)
    current_code = int(match.group(2))
    new_code = current_code + 1
    logger.info(f"🚀 Upgrading Version Code: {current_code} → {new_code}")
    return f"{prefix}{new_code}"

new_content = re.sub(pattern, increment_version, content)

# 3. حفظ التعديل في الملف
with open(file_path, 'w', encoding='utf-8') as file:
    file.write(new_content)

# 4. تنفيذ أمر البناء
logger.info("🏗️  Starting Flutter Build...")
try:
    subprocess.run(
        ["flutter", "build", "appbundle", "--release", "--flavor", "googlePlay"],
        check=True
    )
    logger.info("✅ Build Completed Successfully!")
    logger.info("📦 Output: build/app/outputs/bundle/googlePlayRelease/app-googlePlay-release.aab")
except subprocess.CalledProcessError as e:
    logger.error(f"❌ Build Failed: {e}")
    sys.exit(1)
