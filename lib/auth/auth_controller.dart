import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';
import 'auth_user.dart';
class AuthController extends ChangeNotifier {
  AuthController({required String baseUrl}) : api = AuthApi(baseUrl: baseUrl) {
    _init();
  }

  final AuthApi api;

  static const _kRememberMeKey = 'auth_remember_me';
  static const _kSavedIdentityKey = 'auth_saved_identity';
  static const _kAccessTokenKey = 'auth_access_token';

  bool initialized = false;

  bool loading = false;
  String? error;

  bool rememberMe = false;
  String savedIdentity = '';

  AuthUser? user;
  String? _tokenInMemory;

  bool resetLoading = false;
  String? resetError;

  bool get isLoggedIn => user != null && (token ?? '').isNotEmpty;
  String? get token => _tokenInMemory;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    rememberMe = prefs.getBool(_kRememberMeKey) ?? false;
    savedIdentity = prefs.getString(_kSavedIdentityKey) ?? '';

    if (rememberMe) {
      final storedToken = prefs.getString(_kAccessTokenKey);
      if (storedToken != null && storedToken.isNotEmpty) {
        _tokenInMemory = storedToken;
        await tryAccount();
      } else {
        _tokenInMemory = null;
      }
    } else {
      _tokenInMemory = null;
      await prefs.remove(_kAccessTokenKey);
    }

    initialized = true;
    notifyListeners();
  }

  Future<void> setRememberMe(bool value) async {
    rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRememberMeKey, value);

    if (!value) {
      await prefs.remove(_kAccessTokenKey);
    }
    notifyListeners();
  }

  Future<void> _setSavedIdentity(String identity) async {
    savedIdentity = identity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedIdentityKey, identity);
  }

  /// Returns true if login succeeded and account was loaded.
  Future<bool> login({
    required String identity,
    required String password,
  }) async {
    error = null;
    loading = true;
    notifyListeners();

    try {
      final jwt = await api.login(
        username: identity.trim(),
        password: password,
        rememberMe: rememberMe,
      );

      _tokenInMemory = jwt;
      await _setSavedIdentity(identity.trim());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kRememberMeKey, rememberMe);

      if (rememberMe) {
        await prefs.setString(_kAccessTokenKey, jwt);
      } else {
        await prefs.remove(_kAccessTokenKey);
      }

      final ok = await tryAccount();
      if (!ok) {
        error = error ?? 'Login succeeded but failed to load account.';
      }
      return ok;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Returns true if account was fetched and user was set.
  Future<bool> tryAccount() async {
    try {
      final t = token;
      if (t == null || t.isEmpty) return false;

      final json = await api.getAccount(token: t);
      user = AuthUser.fromJHipsterAccountJson(json);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    user = null;
    _tokenInMemory = null;
    error = null;
    loading = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessTokenKey);

    notifyListeners();
  }

  Future<bool> requestPasswordReset({required String email}) async {
    resetError = null;
    resetLoading = true;
    notifyListeners();

    try {
      await api.resetInit(email: email.trim());
      return true;
    } catch (e) {
      resetError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      resetLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finishPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    resetError = null;
    resetLoading = true;
    notifyListeners();

    try {
      await api.resetFinish(key: code.trim(), newPassword: newPassword);
      return true;
    } catch (e) {
      resetError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      resetLoading = false;
      notifyListeners();
    }
  }
}
