# Hero Animation — Overlaps Search Bar & NavBar

**Status:** 🔒 Key Debug Only (locked until resolved)  
**Severity:** Medium

---

## Summary

During Hero transition between note card and note editor, the Hero widget renders above the search bar and bottom navigation bar for a brief moment before disappearing. Additionally, spacing/layout shifts occur during the transition.

## Symptoms

- Hero animation visually overlaps the search bar (top) and NavBar (bottom) mid-flight
- Layout spacing inconsistencies appear during the push/pop navigation transition
- Issue is reproducible on both mobile and desktop layouts

## Root Cause

Not yet investigated.  
Likely related to Hero overlay layer rendering order — the Hero widget flies through the `Overlay` which sits above all route-level widgets including AppBar and BottomNavigationBar.

## Current Mitigation

Feature is restricted to `kDebugMode` only (Key Debug section in settings) until a proper fix is implemented.

## Affected Files

- `lib/screens/shared/settings/sections/general_section.dart` — `BetaSection` / `heroAnimationEnabled`
- Hero usage sites in note card → editor navigation

---

*Reported: 2025 | Fix: Pending*
