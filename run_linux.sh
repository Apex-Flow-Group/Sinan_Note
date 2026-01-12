#!/bin/bash
# Run Sinan Note on Linux (Fedora/RHEL)
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
flutter run -d linux
