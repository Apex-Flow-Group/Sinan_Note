// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/rate_limiter_service.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
  // Setup: مرحلتان (إنشاء + تأكيد)
  bool _isConfirmStep = false;

  String _pin = '';
  String _firstPin = ''; // يُحفظ عند الانتقال لخطوة التأكيد
  String? _error;
  bool _loading = false;
  bool _biometricAvailable = false;
  bool _isLocked = false;
  int _remainingLockTime = 0;
  int _remainingAttempts = 5;

  // الطول المحدد من الخطوة الأولى (يُقفل عند الانتقال للتأكيد)
  int get _targetLength => _isConfirmStep ? _firstPin.length : _maxPinLength;

  // لون الشريط
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
      
      if (_isLocked) {
        _startLockTimer();
      }
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
    // تحقق من إعداد البصمة ودعم الجهاز
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
    // عند خطوة التأكيد يكتمل تلقائياً عند الوصول للطول المحدد
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
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;

    // التحقق من القفل
    if (!widget.isSetup) {
      final lockTime = await RateLimiterService.getRemainingLockTime();
      if (lockTime != null) {
        setState(() {
          _isLocked = true;
          _remainingLockTime = lockTime;
          _error = 'Locked for ${RateLimiterService.formatRemainingTime(lockTime)}';
          _pin = '';
        });
        _shake();
        return;
      }
    }

    if (widget.isSetup) {
      if (!_isConfirmStep) {
        // الانتقال لخطوة التأكيد
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

      // التحقق من التطابق
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
      widget.onSuccess?.call();
    } else {
      setState(() => _loading = true);
      try {
        final valid = await UnifiedLockService().verifyPin(_pin);
        if (!valid) {
          // تسجيل محاولة فاشلة
          final lockTime = await RateLimiterService.recordFailedAttempt();
          final attempts = await RateLimiterService.getRemainingAttempts();
          
          _shake();
          setState(() {
            if (lockTime != null) {
              _isLocked = true;
              _remainingLockTime = lockTime;
              _error = 'Locked for ${RateLimiterService.formatRemainingTime(lockTime)}';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: widget.isSetup, // السماح بالرجوع فقط عند الإنشاء
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && widget.isSetup && _isConfirmStep) {
          // إذا كان في خطوة التأكيد، الرجوع للخطوة الأولى
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
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        appBar: widget.isSetup
            ? AppBar(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
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
                  statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                ),
              )
            : null,
        body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // أيقونة
                  ScaleTransition(
                    scale: _iconScaleAnim,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: _iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_iconData, size: 40, color: _iconColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // العنوان
                  Text(
                    _title(l10n),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // رسالة الخطأ أو الوصف
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLocked
                        ? Column(
                            key: const ValueKey('locked'),
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.red,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n.tooManyAttempts,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${l10n.tryAgainIn} ${RateLimiterService.formatRemainingTime(_remainingLockTime)}',
                                style: TextStyle(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : _error != null
                            ? Column(
                                key: ValueKey(_error),
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : !widget.isSetup && _remainingAttempts < 5
                                ? Text(
                                    '$_remainingAttempts ${l10n.attemptsRemaining}',
                                    key: ValueKey(_remainingAttempts),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                : Text(
                                _subtitle(l10n),
                                key: const ValueKey('subtitle'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                  ),
                  const SizedBox(height: 32),
                  // مربعات PIN — ديناميكية
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final offset = _shakeController.isAnimating
                          ? 8 * (0.5 - (_shakeAnim.value - 0.5).abs()) * 2
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(offset * 10, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pin.isEmpty ? 1 : _pin.length.clamp(1, _maxPinLength),
                        (i) {
                          final filled = i < _pin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: filled
                                  ? Colors.blue
                                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: filled
                                    ? Colors.blue
                                    : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                                width: 2,
                              ),
                            ),
                            child: filled
                                ? widget.isSetup
                                    ? Center(
                                        child: Text(
                                          _pin.length > i ? _pin[i] : '',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.circle, size: 14, color: Colors.white)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  // مؤشر التقدم — فقط عند الإنشاء
                  if (widget.isSetup) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 240,
                      child: Column(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: AnimatedFractionallySizedBox(
                                widthFactor: (_pin.length / _targetLength).clamp(0.0, 1.0),
                                alignment: AlignmentDirectional.centerStart,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: Container(
                                  color: _progressColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 11,
                              color: _progressColor,
                            ),
                            child: Text(
                              '${_pin.length} / $_targetLength',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // لوحة الأرقام
            _buildNumpad(isDark, l10n),
          ],
        ),
      ),
    ));
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
    if (!widget.isSetup) return Icons.lock_outline;
    return _isConfirmStep ? Icons.check_circle_outline : Icons.lock_outline;
  }

  Color get _iconColor {
    if (!widget.isSetup) return Colors.blue;
    return _isConfirmStep ? Colors.green : Colors.blue;
  }

  Widget _buildNumpad(bool isDark, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _numRow(['1', '2', '3'], isDark),
          const SizedBox(height: 12),
          _numRow(['4', '5', '6'], isDark),
          const SizedBox(height: 12),
          _numRow(['7', '8', '9'], isDark),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // زر البصمة أو فراغ
              SizedBox(
                width: 72, height: 72,
                child: _biometricAvailable && !widget.isSetup
                    ? _numpadKey(
                        child: const Icon(Icons.fingerprint, size: 28),
                        onTap: _tryBiometric,
                        isDark: isDark,
                        color: Colors.teal,
                      )
                    : const SizedBox.shrink(),
              ),
              _numpadKey(
                child: Text('0',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87)),
                onTap: () => _onDigit('0'),
                isDark: isDark,
              ),
              SizedBox(
                width: 72, height: 72,
                child: _numpadKey(
                  child: const Icon(Icons.backspace_outlined, size: 24),
                  onTap: _onDelete,
                  onLongPress: () => setState(() => _pin = ''),
                  isDark: isDark,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          // زر التأكيد — دائم الظهور، معطّل حتى الوصول للحد الأدنى
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_loading || _isLocked) ? null : (_isConfirmStep
                    ? (_pin == _firstPin ? _onConfirm : null)
                    : (_pin.length >= _minPinLength ? _onConfirm : null)),
                icon: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(widget.isSetup ? Icons.check : (widget.isDisabling ? Icons.lock_open : Icons.lock_open)),
                label: _loading ? const SizedBox.shrink() : Text(
                  widget.isSetup
                      ? (_isConfirmStep ? l10n.savePinButton : l10n.next)
                      : (widget.isDisabling ? l10n.disabled : l10n.unlock),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isSetup ? Colors.blue : (widget.isDisabling ? Colors.orange : Colors.blue),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _numpadKey(
                child: Text(d,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87)),
                onTap: () => _onDigit(d),
                isDark: isDark,
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
  }) {
    return SizedBox(
      width: 72, height: 72,
      child: Material(
        color: color != null
            ? color.withValues(alpha: 0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: color ?? (isDark ? Colors.white : Colors.black87)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
