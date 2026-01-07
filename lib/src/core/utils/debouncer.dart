// lib/src/core/utils/debouncer.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Run the action after debounce delay
  void run(VoidCallback action) {
    // Cancel previous timer if exists
    _timer?.cancel();
    
    // Create new timer
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancel any pending action
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Dispose debouncer (call this in dispose method)
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if there's a pending action
  bool get isActive => _timer?.isActive ?? false;
}

// ============================================
// ALTERNATIVE: Advanced Debouncer with callback
// ============================================
class AdvancedDebouncer {
  final int milliseconds;
  Timer? _timer;
  VoidCallback? _lastAction;

  AdvancedDebouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _lastAction = action;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _lastAction?.call();
      _lastAction = null;
    });
  }

  /// Execute immediately without waiting
  void runImmediate(VoidCallback action) {
    _timer?.cancel();
    _lastAction = null;
    action.call();
  }

  void cancel() {
    _timer?.cancel();
    _lastAction = null;
  }

  void dispose() {
    cancel();
  }

  bool get isActive => _timer?.isActive ?? false;
  
  bool get hasPendingAction => _lastAction != null;
}