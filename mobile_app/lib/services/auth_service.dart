import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/app_languages.dart';
import 'firebase_bootstrap.dart';

class AuthFlowException implements Exception {
  const AuthFlowException(this.code, {this.details});

  final String code;
  final String? details;

  @override
  String toString() => details ?? code;
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  String? _token;
  String? _shopId;
  String? _email;
  String? _shopName;
  String? _shopCurrency;
  String? _preferredLanguage;

  String? get token => _token;
  String? get shopId => _shopId;
  String? get email => _email;
  String? get shopName => _shopName;
  String get shopCurrencyCode =>
      (_shopCurrency == null || _shopCurrency!.trim().isEmpty)
          ? AppConfig.defaultCurrencyCode
          : _shopCurrency!.trim().toUpperCase();
  String get preferredLanguageCode => AppLanguages.normalize(
        _preferredLanguage,
        fallback: AppLanguages.defaultCode,
      );
  Locale get locale => AppLanguages.localeOf(preferredLanguageCode);
  bool get isLoggedIn => _token != null;
  bool get isFirebaseConfigured => FirebaseBootstrap.isConfigured;
  String? get currentFirebaseEmail =>
      FirebaseAuth.instance.currentUser?.email ?? _email;

  Map<String, dynamic>? pendingGuestReceipt;

  static const _kToken = 'auth_token';
  static const _kShopId = 'auth_shop_id';
  static const _kEmail = 'auth_email';
  static const _kShopName = 'auth_shop_name';
  static const _kShopCurrency = 'auth_shop_currency';
  static const _kPreferredLanguage = 'auth_preferred_language';

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _shopId = prefs.getString(_kShopId);
    _email = prefs.getString(_kEmail);
    _shopName = prefs.getString(_kShopName);
    _shopCurrency =
        prefs.getString(_kShopCurrency) ?? AppConfig.defaultCurrencyCode;
    _preferredLanguage =
        prefs.getString(_kPreferredLanguage) ?? AppLanguages.defaultCode;

    final firebaseReady = await FirebaseBootstrap.ensureInitialized();
    if (firebaseReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _clearAuthPersistence(prefs);
        _clearSessionState(notify: false);
      } else {
        _email = user.email ?? _email;
        await refreshSessionToken(forceRefresh: true, notify: false);
      }
    }

    notifyListeners();
  }

  Map<String, String> requestHeaders({
    bool includeAuth = false,
    Map<String, String>? extra,
  }) {
    final headers = <String, String>{
      'X-User-Language': preferredLanguageCode,
      ...?extra,
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, String>> requestHeadersAsync({
    bool includeAuth = false,
    Map<String, String>? extra,
  }) async {
    if (includeAuth) {
      await refreshSessionToken();
    }
    return requestHeaders(includeAuth: includeAuth, extra: extra);
  }

  Future<void> register(
    String email,
    String password,
    String shopName,
  ) async {
    await _ensureFirebaseReady();

    UserCredential? credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      final idToken = await user?.getIdToken(true);
      if (user == null || idToken == null) {
        throw const AuthFlowException('auth_unexpected');
      }

      final body = await _backendAuthRequest(
        endpoint: '/api/auth/register',
        payload: {
          'idToken': idToken,
          'email': email,
          'shop_name': shopName,
          'preferred_language': preferredLanguageCode,
        },
        expectedStatusCode: 201,
      );

      await _saveSession(
        body,
        tokenOverride: idToken,
        emailOverride: user.email,
      );
    } on FirebaseAuthException catch (error) {
      await _rollbackFreshFirebaseUser(credential?.user);
      throw _mapFirebaseAuthException(error);
    } on AuthFlowException {
      await _rollbackFreshFirebaseUser(credential?.user);
      rethrow;
    } catch (error) {
      await _rollbackFreshFirebaseUser(credential?.user);
      throw const AuthFlowException('auth_unexpected');
    }
  }

  Future<void> login(String email, String password) async {
    await _ensureFirebaseReady();

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      final idToken = await user?.getIdToken(true);
      if (user == null || idToken == null) {
        throw const AuthFlowException('auth_unexpected');
      }

      final body = await _backendAuthRequest(
        endpoint: '/api/auth/login',
        payload: {
          'idToken': idToken,
          'email': email,
          'preferred_language': preferredLanguageCode,
        },
      );

      await _saveSession(
        body,
        tokenOverride: idToken,
        emailOverride: user.email,
      );
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    } on AuthFlowException catch (error) {
      if (error.code != 'account_setup_required') {
        await FirebaseAuth.instance.signOut().catchError((_) => null);
      }
      rethrow;
    } catch (_) {
      await FirebaseAuth.instance.signOut().catchError((_) => null);
      throw const AuthFlowException('auth_unexpected');
    }
  }

  Future<void> completeShopSetup(String shopName) async {
    await _ensureFirebaseReady();

    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken(true);
    if (user == null || idToken == null) {
      throw const AuthFlowException('auth_unexpected');
    }

    final body = await _backendAuthRequest(
      endpoint: '/api/auth/setup-shop',
      payload: {
        'idToken': idToken,
        'email': user.email,
        'shop_name': shopName,
        'preferred_language': preferredLanguageCode,
      },
    );

    await _saveSession(
      body,
      tokenOverride: idToken,
      emailOverride: user.email,
    );
  }

  Future<void> logout() async {
    try {
      if (await FirebaseBootstrap.ensureInitialized()) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // Best-effort sign-out; local state is still cleared below.
    }

    _clearSessionState(notify: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearAuthPersistence(prefs);
    } catch (_) {
      // Ignore web storage errors.
    }
  }

  Future<void> refreshSessionToken({
    bool forceRefresh = false,
    bool notify = true,
  }) async {
    final firebaseReady = await FirebaseBootstrap.ensureInitialized();
    if (!firebaseReady) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final freshToken = await user.getIdToken(forceRefresh);
    if (freshToken == null) {
      return;
    }

    final changed = freshToken != _token || user.email != _email;
    _token = freshToken;
    _email = user.email ?? _email;

    if (changed) {
      await _persistSessionState();
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> updatePreferredLanguage(String languageCode) async {
    final normalized = AppLanguages.normalize(languageCode);
    final previous = preferredLanguageCode;

    if (normalized == previous) {
      return;
    }

    _preferredLanguage = normalized;
    notifyListeners();
    await _persistPreferredLanguage();

    if (!isLoggedIn) {
      return;
    }

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/api/auth/preferences');
      final response = await http.put(
        uri,
        headers: await requestHeadersAsync(
          includeAuth: true,
          extra: {'Content-Type': 'application/json'},
        ),
        body: jsonEncode({'preferred_language': normalized}),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200) {
        throw Exception(body['error'] ?? 'Language update failed.');
      }

      _preferredLanguage = AppLanguages.normalize(
        body['preferredLanguage']?.toString(),
        fallback: normalized,
      );
      notifyListeners();
      await _persistPreferredLanguage();
    } catch (_) {
      _preferredLanguage = previous;
      notifyListeners();
      await _persistPreferredLanguage();
      rethrow;
    }
  }

  Future<void> _importPendingReceipt() async {
    if (pendingGuestReceipt == null || _token == null) {
      return;
    }

    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/api/receipts/import');
      final res = await http.post(
        uri,
        headers: await requestHeadersAsync(
          includeAuth: true,
          extra: {'Content-Type': 'application/json'},
        ),
        body: jsonEncode({'receiptData': pendingGuestReceipt}),
      );
      if (res.statusCode == 201) {
        pendingGuestReceipt = null;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[AuthService] Import failed: $error');
      }
    }
  }

  Future<Map<String, dynamic>> _backendAuthRequest({
    required String endpoint,
    required Map<String, dynamic> payload,
    int expectedStatusCode = 200,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
    final response = await http.post(
      uri,
      headers: requestHeaders(
        extra: {'Content-Type': 'application/json'},
      ),
      body: jsonEncode(payload),
    );

    final body = _decodeJson(response.body);
    if (response.statusCode != expectedStatusCode) {
      final errorText = body['error']?.toString();
      if (response.statusCode == 404) {
        throw AuthFlowException(
          'account_setup_required',
          details: errorText,
        );
      }
      throw AuthFlowException('auth_unexpected', details: errorText);
    }

    return body;
  }

  Future<void> _saveSession(
    Map<String, dynamic> body, {
    String? tokenOverride,
    String? emailOverride,
  }) async {
    _token = tokenOverride ?? body['token'] as String?;
    _shopId = body['shopId'] as String?;
    _email = emailOverride ?? body['email'] as String?;
    _shopName = body['shopName'] as String?;
    _shopCurrency =
        (body['currency'] as String?) ?? AppConfig.defaultCurrencyCode;
    _preferredLanguage = AppLanguages.normalize(
      body['preferredLanguage']?.toString(),
      fallback: preferredLanguageCode,
    );

    if (pendingGuestReceipt != null) {
      await _importPendingReceipt();
    }

    notifyListeners();
    await _persistSessionState();
  }

  Future<void> _persistSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString(_kToken, _token!);
      }
      if (_shopId != null) {
        await prefs.setString(_kShopId, _shopId!);
      }
      if (_email != null) {
        await prefs.setString(_kEmail, _email!);
      }
      if (_shopName != null) {
        await prefs.setString(_kShopName, _shopName!);
      }
      await prefs.setString(_kShopCurrency, shopCurrencyCode);
      await prefs.setString(_kPreferredLanguage, preferredLanguageCode);
    } catch (_) {
      // Session still works in-memory if persistence fails.
    }
  }

  Future<void> _persistPreferredLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPreferredLanguage, preferredLanguageCode);
    } catch (_) {
      // Ignore storage failures; in-memory locale still updates the app.
    }
  }

  Future<void> _ensureFirebaseReady() async {
    final ready = await FirebaseBootstrap.ensureInitialized();
    if (!ready) {
      if (kDebugMode) {
        final error = FirebaseBootstrap.lastError;
        final stackTrace = FirebaseBootstrap.lastStackTrace;
        debugPrint('[AuthService] Firebase is unavailable for auth requests.');
        if (error != null) {
          debugPrint('[AuthService] Last Firebase error: $error');
        }
        if (stackTrace != null) {
          debugPrintStack(
            label: '[AuthService] Last Firebase stack trace',
            stackTrace: stackTrace,
          );
        }
      }
      throw const AuthFlowException(
        'firebase_not_configured',
      );
    }
  }

  Future<void> _rollbackFreshFirebaseUser(User? user) async {
    if (user == null) {
      return;
    }

    try {
      await user.delete();
    } catch (_) {
      // Ignore rollback failures; backend session is still not established.
    }
  }

  void _clearSessionState({required bool notify}) {
    _token = null;
    _shopId = null;
    _email = null;
    _shopName = null;
    _shopCurrency = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _clearAuthPersistence(SharedPreferences prefs) async {
    await prefs.remove(_kToken);
    await prefs.remove(_kShopId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kShopName);
    await prefs.remove(_kShopCurrency);
  }

  Map<String, dynamic> _decodeJson(String rawBody) {
    try {
      return jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  AuthFlowException _mapFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AuthFlowException('invalid_email', details: error.message);
      case 'email-already-in-use':
        return AuthFlowException('email_already_in_use',
            details: error.message);
      case 'weak-password':
        return AuthFlowException('weak_password', details: error.message);
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFlowException('invalid_credentials', details: error.message);
      case 'network-request-failed':
        return AuthFlowException('network_error', details: error.message);
      case 'too-many-requests':
        return AuthFlowException('too_many_requests', details: error.message);
      default:
        return AuthFlowException('auth_unexpected', details: error.message);
    }
  }
}
