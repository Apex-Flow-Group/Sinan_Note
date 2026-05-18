// Copyright © 2025 Apex Flow Group. All rights reserved.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sinan_note/controllers/settings/settings_provider.dart';
import 'package:sinan_note/generated/l10n/app_localizations.dart';
import 'package:sinan_note/services/security/biometric_service.dart';
import 'package:sinan_note/services/security/rate_limiter_service.dart';
import 'package:sinan_note/services/security/unified_lock_service.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onSuccess;
  final bool autoBiometric;
  final bool isDisabling;

  const PinLockScreen({
    super.key,
    this.isSetup = false,
    this.onSuccess,
    this.autoBiometric = false,
    this.isDisabling = false,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with TickerProviderStateMixin {
  bool _isConfirmStep = false;
  bool _successHandled = false;

  String _pin = '';
  String _firstPin = '';
  String? _error;
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _isLocked = false;
  int _remainingLockTime = 0;
  int _remainingAttempts = 5;

  int get _targetLength => _isConfirmStep ? _firstPin.length : _maxPinLength;

  Color get _progressColor {
    if (_isConfirmStep) {
      if (_pin.length < _firstPin.length) return Colors.orange;
      return _pin == _firstPin ? Colors.green : Colors.red;
    }
    if (_pin.length >= _maxPinLength) return Colors.green;
    if (_pin.length >= _minPinLength) return Colors.blue;
    return Colors.orange;
  }

  static const int _minPinLength = 4;
  static const int _maxPinLength = 6;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  late final AnimationController _iconAnimController;
  late final Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScaleAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconAnimController.forward();

    if (!widget.isSetup) {
      _checkLockStatus();
      _initBiometric();
    }
  }

  Future<void> _checkLockStatus() async {
    final lockTime = await RateLimiterService.getRemainingLockTime();
    final attempts = await RateLimiterService.getRemainingAttempts();

    if (mounted) {
      setState(() {
        _isLocked = lockTime != null;
        _remainingLockTime = lockTime ?? 0;
        _remainingAttempts = attempts;
      });

      if (_isLocked) _startLockTimer();
    }
  }

  void _startLockTimer() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted || !_isLocked) return;

      final lockTime = await RateLimiterService.getRemainingLockTime();

      if (lockTime == null) {
        setState(() {
          _isLocked = false;
          _remainingLockTime = 0;
        });
        await _checkLockStatus();
      } else {
        setState(() => _remainingLockTime = lockTime);
        _startLockTimer();
      }
    });
  }

  Future<void> _initBiometric() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final biometricEnabled = settings.biometricLockEnabled;
    final has = biometricEnabled && await BiometricService.hasBiometrics();
    if (mounted) setState(() => _biometricAvailable = has);
    if (has && widget.autoBiometric) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await BiometricService.authenticate();
    if (ok && mounted) {
      UnifiedLockService().markAuthenticated();
      widget.onSuccess?.call();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _iconAnimController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_isLocked) return;
    if (_pin.length >= _targetLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_isConfirmStep && _pin.length == _firstPin.length) {
      Future.delayed(const Duration(milliseconds: 150), _onPinComplete);
    }
  }

  void _onConfirm() {
    if (_isLocked) return;
    if (_pin.length < _minPinLength) return;
    _onPinComplete();
  }

  void _onDelete() {
    if (_isLocked) return;
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (_loading || _successHandled) return;
    final l10n = AppLocalizations.of(context)!;

    if (!widget.isSetup) {
      final lockTime = await RateLimiterService.getRemainingLockTime();
      if (lockTime != null) {
        setState(() {
          _isLocked = true;
          _remainingLockTime = lockTime;
          _error =
              'Locked for ${RateLimiterService.formatRemainingTime(lockTime)}';
          _pin = '';
        });
        _shake();
        return;
      }
    }

    if (widget.isSetup) {
      if (!_isConfirmStep) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirmStep = true;
        });
        _iconAnimController
          ..reset()
          ..forward();
        return;
      }

      if (_pin != _firstPin) {
        _shake();
        setState(() {
          _error = l10n.pinMismatchError;
          _pin = '';
          _firstPin = '';
          _isConfirmStep = false;
        });
        _iconAnimController
          ..reset()
          ..forward();
        return;
      }

      await UnifiedLockService().setPin(_pin);
      UnifiedLockService().markAuthenticated();
      await RateLimiterService.reset();
      _successHandled = true;
      widget.onSuccess?.call();
    } else {
      setState(() => _loading = true);
      try {
        final valid = await UnifiedLockService().verifyPin(_pin);
        if (!valid) {
          final lockTime = await RateLimiterService.recordFailedAttempt();
          final attempts = await RateLimiterService.getRemainingAttempts();

          _shake();
          setState(() {
            if (lockTime != null) {
              _isLocked = true;
              _remainingLockTime = lockTime;
              _error =
                  'Locked for ${RateLimiterService.formatRemainingTime(lockTime)}';
              _startLockTimer();
            } else {
              _error = null;
              _remainingAttempts = attempts;
            }
            _pin = '';
            _loading = false;
          });
          return;
        }
        await RateLimiterService.reset();
        UnifiedLockService().markAuthenticated();
        _successHandled = true;
        widget.onSuccess?.call();
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _shake() {
    HapticFeedback.vibrate();
    _shakeController
      ..reset()
      ..forward();
  }

  // ─────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 700;

    return PopScope(
      canPop: widget.isSetup,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.isSetup && _isConfirmStep) {
          setState(() {
            _isConfirmStep = false;
            _pin = '';
            _firstPin = '';
            _error = null;
          });
          _iconAnimController
            ..reset()
            ..forward();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor:
            isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
        appBar: widget.isSetup
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () {
                    if (_isConfirmStep) {
                      setState(() {
                        _isConfirmStep = false;
                        _pin = '';
                        _firstPin = '';
                        _error = null;
                      });
                      _iconAnimController
                        ..reset()
                        ..forward();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // ═══════════════════════════════════════════════
                  // الجزء العلوي: الأيقونة + العنوان + العرض + الشريط
                  // ═══════════════════════════════════════════════
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // الأيقونة
                            ScaleTransition(
                              scale: _iconScaleAnim,
                              child: Container(
                                width: isCompact ? 56 : 68,
                                height: isCompact ? 56 : 68,
                                decoration: BoxDecoration(
                                  color: _iconColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _iconColor.withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _iconData,
                                  size: isCompact ? 28 : 32,
                                  color: _iconColor,
                                ),
                              ),
                            ),

                            SizedBox(height: isCompact ? 12 : 16),

                            // العنوان
                            Text(
                              _title(l10n),
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            // الوصف أو رسالة الخطأ
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _buildStatusMessage(l10n, isDark),
                            ),

                            SizedBox(height: isCompact ? 20 : 28),

                            // مربعات PIN
                            AnimatedBuilder(
                              animation: _shakeAnim,
                              builder: (context, child) {
                                final offset = _shakeController.isAnimating
                                    ? 8 *
                                        (0.5 - (_shakeAnim.value - 0.5).abs()) *
                                        2
                                    : 0.0;
                                return Transform.translate(
                                  offset: Offset(offset * 10, 0),
                                  child: child,
                                );
                              },
                              child: _buildPinDots(isDark),
                            ),

                            // شريط التقدم — فقط عند الإنشاء
                            if (widget.isSetup) ...[
                              SizedBox(height: isCompact ? 12 : 16),
                              _buildProgressBar(isDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ═══════════════════════════════════════════════
                  // الجزء السفلي: لوحة الأرقام + زر التأكيد
                  // ═══════════════════════════════════════════════
                  _buildNumpad(isDark, l10n, isCompact),

                  SizedBox(height: isCompact ? 8 : 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// رسالة الحالة (خطأ / قفل / وصف)
  Widget _buildStatusMessage(AppLocalizations l10n, bool isDark) {
    if (_isLocked) {
      return Column(
        key: const ValueKey('locked'),
        children: [
          Icon(Icons.timer_outlined, color: Colors.red[400], size: 24),
          const SizedBox(height: 4),
          Text(
            l10n.tooManyAttempts,
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${l10n.tryAgainIn} ${RateLimiterService.formatRemainingTime(_remainingLockTime)}',
            style: TextStyle(
              color: Colors.red[300],
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Text(
        _error!,
        key: ValueKey(_error),
        style: TextStyle(color: Colors.red[400], fontSize: 13),
        textAlign: TextAlign.center,
      );
    }

    if (!widget.isSetup && _remainingAttempts < 5) {
      return Text(
        '$_remainingAttempts ${l10n.attemptsRemaining}',
        key: ValueKey(_remainingAttempts),
        style: TextStyle(
          color: Colors.orange[600],
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      _subtitle(l10n),
      key: const ValueKey('subtitle'),
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.grey[500] : Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// مربعات PIN
  Widget _buildPinDots(bool isDark) {
    final displayCount = _isConfirmStep
        ? _firstPin.length
        : (_pin.isEmpty ? _maxPinLength : _pin.length.clamp(1, _maxPinLength));

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // حساب حجم المربع بناءً على العرض المتاح
        final totalMargin = displayCount * 6.0; // 3px margin on each side
        final dotSize =
            ((availableWidth - totalMargin) / displayCount).clamp(32.0, 44.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(displayCount, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: filled
                    ? _progressColor
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[200]),
                borderRadius: BorderRadius.circular(dotSize * 0.25),
                border: Border.all(
                  color: filled
                      ? _progressColor
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: 0.5,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: _progressColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: filled
                  ? widget.isSetup
                      ? Center(
                          child: Text(
                            _pin.length > i ? _pin[i] : '',
                            style: TextStyle(
                              fontSize: dotSize * 0.55,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.circle,
                              size: dotSize * 0.3, color: Colors.white),
                        )
                  : null,
            );
          }),
        );
      },
    );
  }

  /// شريط التقدم
  Widget _buildProgressBar(bool isDark) {
    return SizedBox(
      width: 200,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isDark ? Colors.grey[800] : Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: AnimatedFractionallySizedBox(
                widthFactor: (_pin.length / _targetLength).clamp(0.0, 1.0),
                alignment: AlignmentDirectional.centerStart,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  decoration: BoxDecoration(
                    color: _progressColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _progressColor.withValues(alpha: 0.8),
            ),
            child: Text(
              '${_pin.length} / $_targetLength',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// لوحة الأرقام
  Widget _buildNumpad(bool isDark, AppLocalizations l10n, bool isCompact) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final padH = availableWidth > 320 ? 40.0 : 24.0;
        final usableWidth = availableWidth - (padH * 2);
        final keySize = ((usableWidth - 24) / 3).clamp(48.0, 68.0);
        final spacing = isCompact ? 8.0 : 10.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padH),
          child: Column(
            children: [
              _numRow(['1', '2', '3'], isDark, keySize, spacing),
              SizedBox(height: spacing),
              _numRow(['4', '5', '6'], isDark, keySize, spacing),
              SizedBox(height: spacing),
              _numRow(['7', '8', '9'], isDark, keySize, spacing),
              SizedBox(height: spacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: keySize,
                    height: keySize,
                    child: _biometricAvailable && !widget.isSetup
                        ? _numpadKey(
                            child:
                                const Icon(Icons.fingerprint_rounded, size: 26),
                            onTap: _tryBiometric,
                            isDark: isDark,
                            color: Colors.teal,
                            size: keySize,
                          )
                        : const SizedBox.shrink(),
                  ),
                  _numpadKey(
                    child: Text('0',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                    onTap: () => _onDigit('0'),
                    isDark: isDark,
                    size: keySize,
                  ),
                  SizedBox(
                    width: keySize,
                    height: keySize,
                    child: _numpadKey(
                      child: const Icon(Icons.backspace_rounded, size: 22),
                      onTap: _onDelete,
                      onLongPress: () => setState(() => _pin = ''),
                      isDark: isDark,
                      color: Colors.red,
                      size: keySize,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 12 : 16),
              // زر التأكيد
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_loading || _isLocked)
                      ? null
                      : (_isConfirmStep
                          ? (_pin == _firstPin && _pin.length >= _minPinLength
                              ? _onConfirm
                              : null)
                          : (_pin.length >= _minPinLength ? _onConfirm : null)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _confirmButtonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        (isDark ? Colors.grey[800] : Colors.grey[200]),
                    disabledForegroundColor:
                        (isDark ? Colors.grey[600] : Colors.grey[400]),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isSetup
                                  ? (_isConfirmStep
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded)
                                  : (widget.isDisabling
                                      ? Icons.lock_open_rounded
                                      : Icons.lock_open_rounded),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isSetup
                                  ? (_isConfirmStep
                                      ? l10n.savePinButton
                                      : l10n.next)
                                  : (widget.isDisabling
                                      ? l10n.disabled
                                      : l10n.unlock),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color get _confirmButtonColor {
    if (widget.isSetup) {
      return _isConfirmStep ? Colors.green : Colors.blue;
    }
    return widget.isDisabling ? Colors.orange : Colors.blue;
  }

  String _title(AppLocalizations l10n) {
    if (!widget.isSetup) return l10n.enterPinTitle;
    return _isConfirmStep ? l10n.confirmPinTitle : l10n.createPinTitle;
  }

  String _subtitle(AppLocalizations l10n) {
    if (!widget.isSetup) return l10n.enterPinSubtitle;
    return _isConfirmStep ? l10n.confirmPinSubtitle : l10n.createPinSubtitle;
  }

  IconData get _iconData {
    if (!widget.isSetup) return Icons.lock_outline_rounded;
    return _isConfirmStep
        ? Icons.check_circle_outline_rounded
        : Icons.lock_outline_rounded;
  }

  Color get _iconColor {
    if (!widget.isSetup) return Colors.blue;
    return _isConfirmStep ? Colors.green : Colors.blue;
  }

  Widget _numRow(
      List<String> digits, bool isDark, double keySize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _numpadKey(
                child: Text(d,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87)),
                onTap: () => _onDigit(d),
                isDark: isDark,
                size: keySize,
              ))
          .toList(),
    );
  }

  Widget _numpadKey({
    required Widget child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required bool isDark,
    Color? color,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: color != null
            ? color.withValues(alpha: 0.08)
            : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
        borderRadius: BorderRadius.circular(size / 2),
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: (color ?? Colors.blue).withValues(alpha: 0.15),
          highlightColor: (color ?? Colors.blue).withValues(alpha: 0.08),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                  color: color ?? (isDark ? Colors.white : Colors.black87)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

