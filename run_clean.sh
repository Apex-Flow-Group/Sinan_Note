#!/usr/bin/env bash
# run_clean.sh — flutter run مع فلترة الضجيج
# يُبقي على: I/flutter (print), Reloaded, Restarted, Error, Exception

flutter run "$@" 2>&1 | grep -E \
  "flutter|Reloaded|Restarted|Hot|Error|Exception|FATAL|══|▶|✓|✗|Performing|Syncing|Running|Launching|debug|Observatory|DevTools" \
  | grep -v -E \
  "^W/|^D/|^V/|^I/Choreographer|^I/OpenGL|^I/mali|^I/gralloc|^I/Surface|^I/ViewRootImpl|^I/ActivityThread|^I/chatty|^I/art |eglCodecCommon|libEGL|loaded driver|Loaded plugin|org\.khronos|GraphicBuffer|FrameDisplay|skia|Skia|vulkan|Vulkan|GC_|Alloc|JDWP|dalvik|zygote|System\.err|InputMethodManager|ImeTracker|InputMonitor"
