// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/categories/categories_provider.dart';
import 'package:sinan_note/controllers/notes/notes_provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/core/utils/platform_helper.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/main.dart'
    show
        tabToHomeNotifier,
        currentTabIndexNotifier,
        bottomNavHiddenNotifier,
        pendingIntentNotifier,
        isMainLayoutActive;
import 'package:sinan_note/models/note_mode.dart';
import 'package:sinan_note/screens/auth/pin_lock_screen.dart';
import 'package:sinan_note/screens/desktop/code_tab_responsive.dart';
import 'package:sinan_note/screens/desktop/home_screen_responsive.dart';
import 'package:sinan_note/screens/desktop/reminder_dashboard_responsive.dart';
import 'package:sinan_note/services/security/security_gate.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';
import 'package:sinan_note/services/unified_notification_service.dart';
import 'package:sinan_note/widgets/details_panel.dart';
import 'package:sinan_note/widgets/home/add_menu_widget.dart';
import 'package:sinan_note/widgets/navigation/bottom_nav_bar.dart';
import 'package:sinan_note/widgets/navigation/side_nav_rail.dart';

class MainLayoutScreen extends StatefulWidget {
  final String? sharedText;

  const MainLayoutScreen({
    super.key,
    this.sharedText,
  });

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  bool _isScrollHidden = false;
  bool _isDrawerOpen = false;
  bool _showAddMenu = false;
  void Function(NoteMode)? _onModeSelected;
  final _securityController = SecurityController();
  DateTime? _lastBackPress;

  // ✅ Cache screens to prevent rebuilds
  late final List<Widget> _cachedScreens;
  late final Widget _sharedDetailsPanel;

  @override
  void initState() {
    super.initState();
    _securityController.addListener(_onSecurityChanged);
    tabToHomeNotifier.addListener(_onBackToHome);

    // تسجيل callback المزامنة فوراً — لضمان عدم فقدان sync events مبكرة
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    final categoriesProvider =
        Provider.of<CategoriesProvider>(context, listen: false);
    notesProvider.stateService.onCategoriesRefreshNeeded =
        () => categoriesProvider.refreshCategories();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PlatformHelper.lockOrientationForMobile(context);
    });

    // ✅ استهلاك الـ pending intent بعد جاهزية MainLayoutScreen
    // يُنفَّذ هنا بعد اكتمال المصادقة (بصمة أو PIN) لأن SplashScreen لا ينتقل هنا إلا بعد نجاح المصادقة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // عيّن الـ flag دائماً بمجرد mount MainLayoutScreen
      isMainLayoutActive = true;
      _consumePendingIntent();
    });

    pendingIntentNotifier.addListener(_onPendingIntentChanged);

    _sharedDetailsPanel = const DetailsPanel();
    _cachedScreens = [
      NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (!_isDrawerOpen) {
            if (notification.direction == ScrollDirection.reverse) {
              _handleScrollNotification(true);
            } else if (notification.direction == ScrollDirection.forward) {
              _handleScrollNotification(false);
            }
          }
          return false;
        },
        child: HomeScreenResponsive(
          sharedText: widget.sharedText,
          onDrawerChanged: _onDrawerChanged,
          showAddMenu: _showAddMenu,
          onToggleMenu: _toggleMenu,
          onRegisterModeHandler: (handler) => _onModeSelected = handler,
          sharedDetailsPanel: _sharedDetailsPanel,
        ),
      ),
      ReminderDashboardResponsive(sharedDetailsPanel: _sharedDetailsPanel),
      CodeTabResponsive(sharedDetailsPanel: _sharedDetailsPanel),
    ];
  }

  // _autoSyncOnStartup حُذفت — SplashScreen يتولى المزامنة عند الفتح
  // لتجنب مزامنة مزدوجة متزامنة مع splash_screen

  @override
  void dispose() {
    _securityController.removeListener(_onSecurityChanged);
    tabToHomeNotifier.removeListener(_onBackToHome);
    pendingIntentNotifier.removeListener(_onPendingIntentChanged);
    isMainLayoutActive = false;
    PlatformHelper.unlockOrientation();
    super.dispose();
  }

  bool _isConsumingIntent = false;

  /// الاستماع للـ pending intents التي تصل بعد جاهزية MainLayoutScreen
  void _onPendingIntentChanged() {
    if (!mounted || _isConsumingIntent) return;
    _consumePendingIntent();
  }

  /// استهلاك الـ pending intent وتفعيل التنفيذ عبر _ApexNoteAppState
  void _consumePendingIntent() {
    final data = pendingIntentNotifier.value;
    if (data == null) return;

    _isConsumingIntent = true;

    // امسح أولاً لمنع التنفيذ المزدوج
    pendingIntentNotifier.value = null;

    // أعد التعيين — isMainLayoutActive=true الآن، سيُنفَّذ _onPendingIntent في _ApexNoteAppState
    pendingIntentNotifier.value = Map.from(data);

    _isConsumingIntent = false;
  }

  void _onBackToHome() {
    if (_currentIndex != 0 && mounted) {
      setState(() => _currentIndex = 0);
    }
  }

  bool _lockScreenVisible = false;

  void _onSecurityChanged() {
    if (!_securityController.isLocked || !mounted) return;
    // منع فتح شاشة قفل مكررة
    if (_lockScreenVisible) return;
    _lockScreenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      Navigator.of(context)
          .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  PinLockScreen(
                isSetup: false,
                autoBiometric: settings.biometricLockEnabled,
                onSuccess: () {
                  // مارك الجلسة وافتح القفل مباشرة — بدون requestUnlock
                  UnifiedLockService().markAuthenticated();
                  _securityController.forceUnlock();
                  _lockScreenVisible = false;
                  Navigator.of(context).pop();
                },
              ),
              settings: const RouteSettings(name: '/lock'),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          )
          .then((_) => _lockScreenVisible = false);
    });
  }

  void _handleScrollNotification(bool isScrollingDown) {
    if (_currentIndex != 0 || _isDrawerOpen) return;

    final isLargeScreen = PlatformHelper.shouldUseDesktopLayout(context);
    if (isLargeScreen) return;

    // إذا الإعداد معطّل → الشريط ثابت دائماً
    final hideOnScroll =
        Provider.of<SettingsProvider>(context, listen: false).hideNavOnScroll;
    if (!hideOnScroll) return;

    if (isScrollingDown && !_isScrollHidden) {
      setState(() => _isScrollHidden = true);
      bottomNavHiddenNotifier.value = true;
    } else if (!isScrollingDown && _isScrollHidden) {
      setState(() => _isScrollHidden = false);
      bottomNavHiddenNotifier.value = false;
    }
  }

  void _toggleMenu() {
    setState(() => _showAddMenu = !_showAddMenu);
    isMenuOpenNotifier.value = _showAddMenu;
  }

  void _onDrawerChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
      if (!isOpen) {
        _isScrollHidden = false;
        bottomNavHiddenNotifier.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showBottomBar =
        context.select<SettingsProvider, bool>((s) => s.isSetupCompleted) ||
            context.select<NotesProvider, bool>((n) => n.isInitialDataLoaded);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isLargeScreen = PlatformHelper.shouldUseDesktopLayout(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          currentTabIndexNotifier.value = 0;
          return;
        }
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            UnifiedNotificationService().show(
              context: context,
              message: l10n.pressBackToExit,
              type: NotificationType.info,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        onDrawerChanged: _onDrawerChanged,
        body: MediaQuery.removeViewInsets(
          context: context,
          removeBottom: true,
          child: Row(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    IndexedStack(
                      index: _currentIndex,
                      children: _cachedScreens,
                    ),
                    if (showBottomBar && !isLargeScreen)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: BottomNavBar(
                          currentIndex: _currentIndex,
                          onTap: (index) {
                            if (_showAddMenu) _toggleMenu();
                            setState(() {
                              _currentIndex = index;
                              if (index != 0) {
                                _isScrollHidden = false;
                                bottomNavHiddenNotifier.value = false;
                              }
                            });
                            currentTabIndexNotifier.value = index;
                          },
                          isScrollHidden: _isScrollHidden,
                          isDrawerOpen: _isDrawerOpen,
                        ),
                      ),
                    if (!isLargeScreen && !_isDrawerOpen)
                      AddMenuWidget(
                        showMenu: _showAddMenu,
                        onToggle: _toggleMenu,
                        onModeSelected: (mode) {
                          _onModeSelected?.call(mode);
                        },
                      ),
                  ],
                ),
              ),
              if (showBottomBar && isLargeScreen)
                SideNavRail(
                  currentIndex: _currentIndex,
                  onDestinationSelected: (index) {
                    if (isMenuOpenNotifier.value) {
                      isMenuOpenNotifier.value = false;
                    }
                    setState(() {
                      _currentIndex = index;
                      if (index != 0) {
                        _isScrollHidden = false;
                        bottomNavHiddenNotifier.value = false;
                      }
                    });
                    currentTabIndexNotifier.value = index;
                  },
                  onHomeTap: () {
                    // العودة للرئيسية: التأكد أن التبويب 0 نشط
                    if (_currentIndex != 0) {
                      setState(() => _currentIndex = 0);
                      currentTabIndexNotifier.value = 0;
                    } else {
                      // نشط بالفعل — أرسل إشارة للعودة للرئيسية
                      tabToHomeNotifier.value++;
                    }
                  },
                  isScrollHidden: false,
                  isDrawerOpen: _isDrawerOpen,
                  isRTL: isRTL,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
