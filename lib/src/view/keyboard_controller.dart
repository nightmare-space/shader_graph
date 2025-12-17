import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class KeyboardController {
  // Shadertoy-style keyboard texture semantics:
  // row 0: down (latched)
  // row 1: justPressed (one frame)
  // row 2: justReleased (one frame)
  final Set<int> _keysDown = <int>{};
  final Set<int> _pendingJustPressed = <int>{};
  final Set<int> _pendingJustReleased = <int>{};
  final Set<int> _latchedJustPressed = <int>{};
  final Set<int> _latchedJustReleased = <int>{};
  final Map<int, int> _pendingKeyUpAtFrame = <int, int>{};
  static const int kWidth = 256;
  static const int kHeight = 3;
  static const int kChannels = 4;
  final Map<LogicalKeyboardKey, int> _activeKeys = {};

  bool hasKeyBoardInput = false;
  final Uint8List keyboardPixels = Uint8List(kWidth * kHeight * kChannels);

  Future<void> init() async {
    Completer completer = Completer();
    ui.decodeImageFromPixels(
      keyboardPixels,
      256,
      3,
      ui.PixelFormat.rgba8888,
      (img) {
        completer.complete(img);
      },
    );

    keyboardImage = await completer.future;
  }

  void pumpKeyboardFrame(int currentFrame) {
    if (!hasKeyBoardInput) return;

    bool changed = false;

    // Clear previous one-frame pulses.
    if (_latchedJustPressed.isNotEmpty) {
      for (final keyCode in _latchedJustPressed) {
        setKey(keyCode, 1, false);
      }
      _latchedJustPressed.clear();
      changed = true;
    }
    if (_latchedJustReleased.isNotEmpty) {
      for (final keyCode in _latchedJustReleased) {
        setKey(keyCode, 2, false);
      }
      _latchedJustReleased.clear();
      changed = true;
    }

    // Apply delayed key-up so a quick tap is still visible for at least one rendered frame.
    if (_pendingKeyUpAtFrame.isNotEmpty) {
      final keysToClear = <int>[];
      _pendingKeyUpAtFrame.forEach((keyCode, upFrame) {
        if (currentFrame > upFrame) {
          keysToClear.add(keyCode);
        }
      });
      for (final keyCode in keysToClear) {
        _pendingKeyUpAtFrame.remove(keyCode);
        _keysDown.remove(keyCode);
        setKey(keyCode, 0, false);
        changed = true;
      }
    }

    // Latch new pulses for exactly one frame.
    if (_pendingJustPressed.isNotEmpty) {
      for (final keyCode in _pendingJustPressed) {
        setKey(keyCode, 1, true);
      }
      _latchedJustPressed.addAll(_pendingJustPressed);
      _pendingJustPressed.clear();
      changed = true;
    }
    if (_pendingJustReleased.isNotEmpty) {
      for (final keyCode in _pendingJustReleased) {
        setKey(keyCode, 2, true);
      }
      _latchedJustReleased.addAll(_pendingJustReleased);
      _pendingJustReleased.clear();
      changed = true;
    }

    if (changed || _keyboardDirty) {
      _keyboardDirty = false;
      updateKeyboardImage();
    }
  }

  void updateKeyboardImage() async {
    Completer completer = Completer();
    ui.decodeImageFromPixels(
      keyboardPixels,
      kWidth,
      kHeight,
      ui.PixelFormat.rgba8888,
      (img) {
        completer.complete(img);
      },
    );
    final ui.Image newImage = await completer.future;

    // Replace and dispose the old keyboard image to avoid leaks.
    final old = keyboardImage;
    keyboardImage = newImage;
    old?.dispose();
  }

  ui.Image? keyboardImage;
  void setKey(int keyCode, int row, bool on) {
    if (keyCode < 0 || keyCode >= 256) return;
    if (row < 0 || row >= 3) return;

    final int base = (row * kWidth + keyCode) * 4;

    keyboardPixels[base + 0] = on ? 255 : 0; // R
    keyboardPixels[base + 1] = 0; // G
    keyboardPixels[base + 2] = 0; // B
    keyboardPixels[base + 3] = 255; // A
  }

  final Map<LogicalKeyboardKey, int> _specialKeyMap = {
    LogicalKeyboardKey.space: 32, // Space
    LogicalKeyboardKey.enter: 13, // Enter
    LogicalKeyboardKey.escape: 27, // Esc

    LogicalKeyboardKey.arrowLeft: 37,
    LogicalKeyboardKey.arrowUp: 38,
    LogicalKeyboardKey.arrowRight: 39,
    LogicalKeyboardKey.arrowDown: 40,
  };
  int toShadertoyKey(KeyEvent event) {
    // 1. 功能键
    final special = _specialKeyMap[event.logicalKey];
    if (special != null) return special;

    // 2. 只在 KeyDown 使用 character（字符语义）
    if (event is KeyDownEvent) {
      final ch = event.character;
      log('character=${event.character}');
      if (ch != null && ch.length == 1) {
        return ch.codeUnitAt(0);
      }
    }

    // 3. 回退：普通字符键
    final label = event.logicalKey.keyLabel;
    if (label.length == 1) {
      return label.codeUnitAt(0);
    }

    return -1;
  }

  void _keyDownByCode(int keyCode) {
    if (keyCode < 0 || keyCode >= 256) return;
    if (_keysDown.contains(keyCode)) return; // 防止重复

    _keysDown.add(keyCode);
    _pendingJustPressed.add(keyCode);
    _pendingKeyUpAtFrame.remove(keyCode);

    setKey(keyCode, 0, true); // row0: down
    _keyboardDirty = true;
    hasKeyBoardInput = true;
  }

  void _keyUpByCode(int keyCode, int currentFrame) {
    if (!_keysDown.contains(keyCode)) return;

    // Delay clearing row0 until next rendered frame.
    _pendingKeyUpAtFrame[keyCode] = currentFrame;
    _pendingJustReleased.add(keyCode);
    _keyboardDirty = true;
  }

  void pressKey(int keyCode) {
    _keyDownByCode(keyCode);
  }

  void releaseKey(int keyCode, int currentFrame) {
    _keyUpByCode(keyCode, currentFrame);
  }

  void onKeyDown(KeyEvent event) {
    if (_activeKeys.containsKey(event.logicalKey)) return;

    final int keyCode = toShadertoyKey(event);
    if (keyCode < 0) return;

    _activeKeys[event.logicalKey] = keyCode;
    _keyDownByCode(keyCode);
  }

  bool _keyboardDirty = false;

  void onKeyUp(KeyEvent event, int currentFrame) {
    final int? keyCode = _activeKeys.remove(event.logicalKey);
    if (keyCode == null) return;

    _keyUpByCode(keyCode, currentFrame);
  }

  void dispose() {
    keyboardImage?.dispose();
  }
}
