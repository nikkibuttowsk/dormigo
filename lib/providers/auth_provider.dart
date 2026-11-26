import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }

  User? _user;
  bool _isGuest = false;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<AuthState>? _authSub;

  // Editable profile fields (backed by Supabase user_metadata or guest state)
  String _displayName = 'Chloe Yzabelle';
  String _handle = '@chloegonzaga';
  String _dormInfo = 'Dorm Bldg A · Room 204';
  String _preferences = 'Budget · No pork';
  bool _notificationsOn = true;

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _user != null || _isGuest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get email => _user?.email ?? 'guest@dormigo.app';
  String get displayName => _displayName;
  String get handle => _handle;
  String get dormInfo => _dormInfo;
  String get preferences => _preferences;
  bool get notificationsOn => _notificationsOn;

  String? _avatarPath;
  String? get avatarPath => _avatarPath;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  void _init() {
    final client = _client;
    if (client == null) return;

    _user = client.auth.currentUser;
    if (_user != null) {
      _hydrateFromUser(_user!);
    }

    _authSub = client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _isGuest = false;
        _hydrateFromUser(_user!);
      }
      notifyListeners();
    });
  }

  void _hydrateFromUser(User user) {
    final meta = user.userMetadata ?? {};
    _avatarPath = meta['avatar_path'] as String?;
    final emailPrefix = (user.email ?? 'dormigo_user').split('@').first;

    _displayName = (meta['display_name'] as String?)?.trim().isNotEmpty == true
        ? meta['display_name'] as String
        : _capitalize(emailPrefix);

    final rawHandle = (meta['handle'] as String?)?.trim();
    _handle = (rawHandle != null && rawHandle.isNotEmpty)
        ? (rawHandle.startsWith('@') ? rawHandle : '@$rawHandle')
        : '@$emailPrefix';

    _dormInfo = (meta['dorm_info'] as String?) ?? 'Dorm · Room not set';
    _preferences = (meta['preferences'] as String?) ?? 'Budget · No restrictions';
    _notificationsOn = (meta['notifications_on'] as bool?) ?? true;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sign in with Email + Password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase is not configured. Try Continue as Guest.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _user = res.user;
      _isGuest = false;
      if (_user != null) _hydrateFromUser(_user!);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Check your internet connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new account with Email + Password + Display Name
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase is not configured. Try Continue as Guest.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanName = displayName.trim();
      final emailPrefix = email.trim().split('@').first;
      final defaultHandle = '@${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '')}';

      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': cleanName.isNotEmpty ? cleanName : _capitalize(emailPrefix),
          'handle': defaultHandle.length > 1 ? defaultHandle : '@$emailPrefix',
          'dorm_info': 'Dorm · Room not set',
          'preferences': 'Budget · No restrictions',
          'notifications_on': true,
        },
      );

      _user = res.user;
      _isGuest = false;
      if (_user != null) _hydrateFromUser(_user!);

      if (res.session == null && res.user != null) {
        _errorMessage =
            'Account created! Check your email to confirm before logging in.';
        return false;
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Sign up failed. Check your internet connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// without an account -- guest mode
  void continueAsGuest() {
    _user = null;
    _isGuest = true;
    _errorMessage = null;
    _displayName = 'Guest Student';
    _handle = '@guest_dormie';
    _dormInfo = 'Guest Mode · Local session';
    _preferences = 'Budget · No restrictions';
    _notificationsOn = true;
    _avatarPath = null;
    notifyListeners();
  }

  /// Update editable profile & preferences (persists to Supabase if signed in)
  Future<bool> updateProfile({
    String? displayName,
    String? handle,
    String? dormInfo,
    String? preferences,
    bool? notificationsOn,
  }) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _displayName = displayName.trim();
    }
    if (handle != null && handle.trim().isNotEmpty) {
      final clean = handle.trim();
      _handle = clean.startsWith('@') ? clean : '@$clean';
    }
    if (dormInfo != null && dormInfo.trim().isNotEmpty) {
      _dormInfo = dormInfo.trim();
    }
    if (preferences != null) {
      _preferences = preferences;
    }
    if (notificationsOn != null) {
      _notificationsOn = notificationsOn;
    }
    notifyListeners();

    final client = _client;
    if (client == null || _user == null) {
      return true;
    }

    try {
      final res = await client.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': _displayName,
            'handle': _handle,
            'dorm_info': _dormInfo,
            'preferences': _preferences,
            'notifications_on': _notificationsOn,
          },
        ),
      );
      if (res.user != null) {
        _user = res.user;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// sign out
  Future<void> signOut() async {
    final client = _client;
    if (client != null && _user != null) {
      try {
        await client.auth.signOut();
      } catch (_) {
        // Proceed with local cleanup even if network fails
      }
    }
    _user = null;
    _isGuest = false;
    _errorMessage = null;
    _avatarPath = null;
    notifyListeners();
  }

  Future<void> updateAvatar(String? path) async {
  _avatarPath = path;
  notifyListeners();

  final client = _client;
  if (client == null || _user == null) return;

  try {
    await client.auth.updateUser(
      UserAttributes(data: {'avatar_path': _avatarPath}),
    );
  } catch (_) {}
}

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}