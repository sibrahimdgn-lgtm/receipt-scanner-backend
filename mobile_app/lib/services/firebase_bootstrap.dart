import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'firebase_web_plugin_registrant.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _attempted = false;
  static bool _ready = false;
  static Object? _lastError;
  static StackTrace? _lastStackTrace;

  static bool get isConfigured {
    try {
      DefaultFirebaseOptions.currentPlatform;
      return true;
    } on UnsupportedError catch (error, stackTrace) {
      _lastError ??= error;
      _lastStackTrace ??= stackTrace;
      return false;
    }
  }

  static bool get isReady => _ready;
  static Object? get lastError => _lastError;
  static StackTrace? get lastStackTrace => _lastStackTrace;

  static void markReady() {
    _attempted = true;
    _ready = true;
    _lastError = null;
    _lastStackTrace = null;
  }

  static void recordInitializationFailure(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    _attempted = true;
    _ready = false;
    _lastError = error;
    _lastStackTrace = stackTrace;
    debugPrint(
        '[FirebaseBootstrap][$context] Firebase initialization failed: $error');
    debugPrintStack(
      label: '[FirebaseBootstrap][$context] stack trace',
      stackTrace: stackTrace,
    );
  }

  static Future<bool> ensureInitialized() async {
    if (Firebase.apps.isNotEmpty) {
      markReady();
      return true;
    }

    if (_attempted && !_ready) {
      return false;
    }

    _attempted = true;
    if (!isConfigured) {
      _ready = false;
      return false;
    }

    try {
      ensureFirebaseWebPluginsRegistered();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      markReady();
      return true;
    } catch (error, stackTrace) {
      recordInitializationFailure(
        error,
        stackTrace,
        context: 'ensureInitialized',
      );
      return false;
    }
  }
}
