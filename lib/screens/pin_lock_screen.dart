import 'package:flutter/material.dart';
import '../services/pin_service.dart';

class PinLockScreen extends StatefulWidget {
  final bool isSetup;
  final VoidCallback? onUnlock;

  const PinLockScreen({super.key, this.isSetup = false, this.onUnlock});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _confirmPin;
  String? _error;

  void _onKeyPress(String key) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += key;
      _error = null;
    });

    if (_pin.length == 4) {
      if (widget.isSetup) {
        _handleSetup();
      } else {
        _handleUnlock();
      }
    }
  }

  void _handleSetup() {
    if (_confirmPin == null) {
      setState(() {
        _confirmPin = _pin;
        _pin = '';
      });
    } else {
      if (_pin == _confirmPin) {
        PinService.setPin(_pin).then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN 碼設定成功')),
            );
            Navigator.pop(context, true);
          }
        });
      } else {
        setState(() {
          _error = '兩次輸入不一致，請重新設定';
          _pin = '';
          _confirmPin = null;
        });
      }
    }
  }

  void _handleUnlock() async {
    final valid = await PinService.validatePin(_pin);
    if (valid) {
      widget.onUnlock?.call();
    } else {
      setState(() {
        _error = 'PIN 碼錯誤';
        _pin = '';
      });
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_confirmPin == null ? '設定 PIN 碼' : '確認 PIN 碼')
        : '請輸入 PIN 碼';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? const Color(0xFFE94560)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
            const Spacer(flex: 3),
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 80);
                }
                final isBackspace = key == '⌫';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: MaterialButton(
                      onPressed: isBackspace ? _onBackspace : () => _onKeyPress(key),
                      shape: const CircleBorder(),
                      color: isBackspace
                          ? Colors.grey.withValues(alpha: 0.2)
                          : const Color(0xFF1A1A2E),
                      child: isBackspace
                          ? const Icon(Icons.backspace_outlined, color: Colors.white)
                          : Text(
                              key,
                              style: const TextStyle(fontSize: 28),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
