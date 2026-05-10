// Copyright © 2025 Apex Flow Group. All rights reserved.

import 'package:apex_note/controllers/settings/settings_provider.dart';
import 'package:apex_note/generated/l10n/app_localizations.dart';
import 'package:apex_note/services/security/biometric_service.dart';
import 'package:apex_note/services/security/unified_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onSuccess;
  final bool autoBiometric;

  const PinLockScreen({
    super.key,
    this.isSetup = false,
    this.onSuccess,
    this.autoBiometric = false,
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

  // الطول المحدد من الخطوة الأولى (يُقفل عند الانتقال للتأكيد)
  int get _targetLength => _isConfirmStep ? _firstPin.length : _maxPinLength;

  // لون الشريط
  Color get _progressColor {
    if (_isConfirmStep) {
      if (_pin.length < _firstPin.length) return Colors.red;
      return _pin == _firstPin ? Colors.green : Colors.red;
    }
    if (_pin.length >= _maxPinLength) return Colors.green;
    if (_pin.length >= _minPinLength) return Colors.amber;
    return Colors.red;
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

    if (!widget.isSetup) _initBiometric();
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
    if (_pin.length < _minPinLength) return;
    _onPinComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context)!;

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
      widget.onSuccess?.call();
    } else {
      setState(() => _loading = true);
      try {
        final valid = await UnifiedLockService().verifyPin(_pin);
        if (!valid) {
          _shake();
          setState(() {
            _error = l10n.pinIncorrectError;
            _pin = '';
            _loading = false;
          });
          return;
        }
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      appBar: AppBar(
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
      ),
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
                    child: _error != null
                        ? Text(
                            _error!,
                            key: ValueKey(_error),
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                            textAlign: TextAlign.center,
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _pin.length / _targetLength),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
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
    );
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
                onPressed: _loading ? null : (_isConfirmStep
                    ? (_pin == _firstPin ? _onConfirm : null)
                    : (_pin.length >= _minPinLength ? _onConfirm : null)),
                icon: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check),
                label: _loading ? const SizedBox.shrink() : Text(
                  widget.isSetup
                      ? (_isConfirmStep ? l10n.savePinButton : l10n.next)
                      : l10n.unlock,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
