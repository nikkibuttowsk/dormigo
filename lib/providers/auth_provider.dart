import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isGuest = false;
  bool _isLoading = false;
  String? _errorMessage;

  String _displayName = 'Dorm Chef';
  String _handle = '@dorm_chef';
  String _dormInfo = 'Dorm · Room not set';
  String _preferences = 'Budget · No pork';
  bool _notificationsOn = true;
  String? _avatarUrl;

  StreamSubscription<AuthState>? _authSub;
  Future<void> _metadataWriteChain = Future.value();

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Only non-anonymous users with an active session are treated as authenticated.
  bool get isAuthenticated => _user != null && !(_user!.isAnonymous);
  bool get hasSession => isAuthenticated || _isGuest;

  String get displayName => _displayName;
  String get handle => _handle;
  String get dormInfo => _dormInfo;
  String get preferences => _preferences;
  bool get notificationsOn => _notificationsOn;
  String? get avatarUrl => _avatarUrl;
  String get email => _user?.email ?? 'Guest Mode';

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AuthProvider() {
    _init();
  }

  void _init() {
    final client = _client;
    if (client == null) return;

    final currentUser = client.auth.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      _user = currentUser;
      _isGuest = false;
      _hydrateFromUser(currentUser);
    } else if (currentUser != null && currentUser.isAnonymous) {
      _user = null;
      _isGuest = true;
    }

    _authSub = client.auth.onAuthStateChange.listen((data) {
      final sessionUser = data.session?.user;
      if (sessionUser != null && !sessionUser.isAnonymous) {
        _user = sessionUser;
        _isGuest = false;
        _hydrateFromUser(sessionUser);
      } else if (sessionUser != null && sessionUser.isAnonymous) {
        _user = null;
        _isGuest = true;
      } else {
        _user = null;
        if (data.event == AuthChangeEvent.signedOut) {
          _isGuest = false;
          _resetProfileDefaults();
        }
      }
      notifyListeners();
    });
  }

  void _resetProfileDefaults() {
    _displayName = 'Dorm Chef';
    _handle = '@dorm_chef';
    _dormInfo = 'Dorm · Room not set';
    _preferences = 'Budget · No pork';
    _notificationsOn = true;
    _avatarUrl = null;
  }

  void _hydrateFromUser(User user) {
    final meta = user.userMetadata ?? {};
    final emailPrefix = (user.email ?? 'dormigo_user').split('@').first;

    _displayName = (meta['display_name'] as String?)?.trim().isNotEmpty == true
        ? meta['display_name'] as String
        : _capitalize(emailPrefix);

    final rawHandle = (meta['handle'] as String?)?.trim();
    _handle = (rawHandle != null && rawHandle.isNotEmpty)
        ? (rawHandle.startsWith('@') ? rawHandle : '@$rawHandle')
        : '@${emailPrefix.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')}';

    _dormInfo = (meta['dorm_info'] as String?)?.trim().isNotEmpty == true
        ? meta['dorm_info'] as String
        : 'Dorm · Room not set';

    _preferences = (meta['preferences'] as String?)?.trim().isNotEmpty == true
        ? meta['preferences'] as String
        : 'Budget · No pork';

    _notificationsOn = meta['notifications_on'] is bool
        ? meta['notifications_on'] as bool
        : true;

    _avatarUrl = meta['avatar_url'] as String?;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return 'Dorm Chef';
    return value[0].toUpperCase() + value.substring(1);
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

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
      if (res.session == null || res.user == null || res.user!.isAnonymous) {
        _errorMessage = 'Could not establish a valid session.';
        return false;
      }
      _user = res.user;
      _isGuest = false;
      _hydrateFromUser(_user!);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Please check your connection.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
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
      final cleanName = fullName.trim();
      final handleBase = (cleanName.isNotEmpty
              ? cleanName
              : email.trim().split('@').first)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_');

      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (cleanName.isNotEmpty) 'display_name': cleanName,
          'handle': '@$handleBase',
          'dorm_info': 'Dorm · Room not set',
          'preferences': 'Budget · No pork',
          'notifications_on': true,
        },
      );

      // Do not mark the account signed in if email confirmation is required (no session)
      if (res.session == null || res.user == null) {
        _errorMessage =
            'Account created! Please verify your email before signing in.';
        return false;
      }

      _user = res.user;
      _isGuest = false;
      _hydrateFromUser(_user!);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create account. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    final client = _client;
    if (client != null &&
        client.auth.currentUser != null &&
        !client.auth.currentUser!.isAnonymous) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _user = null;
    _isGuest = true;
    _errorMessage = null;
    _resetProfileDefaults();
    notifyListeners();
  }

  /// Serializes partial metadata updates and rolls back local state on failure.
  Future<bool> updateProfile({
    String? displayName,
    String? handle,
    String? dormInfo,
    String? preferences,
    bool? notificationsOn,
  }) {
    final completer = Completer<bool>();
    _metadataWriteChain = _metadataWriteChain.then((_) async {
      final prevName = _displayName;
      final prevHandle = _handle;
      final prevDorm = _dormInfo;
      final prevPrefs = _preferences;
      final prevNotif = _notificationsOn;

      final patch = <String, dynamic>{};

      if (displayName != null && displayName.trim().isNotEmpty) {
        _displayName = displayName.trim();
        patch['display_name'] = _displayName;
      }
      if (handle != null && handle.trim().isNotEmpty) {
        final clean = handle.trim();
        _handle = clean.startsWith('@') ? clean : '@$clean';
        patch['handle'] = _handle;
      }
      if (dormInfo != null) {
        _dormInfo = dormInfo.trim().isEmpty
            ? 'Dorm · Room not set'
            : dormInfo.trim();
        patch['dorm_info'] = _dormInfo;
      }
      if (preferences != null) {
        _preferences = preferences;
        patch['preferences'] = _preferences;
      }
      if (notificationsOn != null) {
        _notificationsOn = notificationsOn;
        patch['notifications_on'] = _notificationsOn;
      }

      if (patch.isEmpty) {
        completer.complete(true);
        return;
      }

      notifyListeners();

      final client = _client;
      if (client == null || !isAuthenticated) {
        // Guest mode: keep changes in memory
        completer.complete(true);
        return;
      }

      try {
        await client.auth.updateUser(UserAttributes(data: patch));
        completer.complete(true);
      } catch (_) {
        // Roll back local changes when Supabase rejects the save
        _displayName = prevName;
        _handle = prevHandle;
        _dormInfo = prevDorm;
        _preferences = prevPrefs;
        _notificationsOn = prevNotif;
        _errorMessage = 'Failed to save profile changes.';
        notifyListeners();
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Uploads avatar to Supabase Storage ('avatars' bucket) so it works across devices.
  Future<bool> updateAvatar(String? localFilePath) async {
    final prevAvatar = _avatarUrl;
    final client = _client;

    if (localFilePath == null) {
      _avatarUrl = null;
      notifyListeners();

      if (client != null && isAuthenticated) {
        try {
          await client.auth.updateUser(
            UserAttributes(data: {'avatar_url': null}),
          );
        } catch (_) {
          _avatarUrl = prevAvatar;
          notifyListeners();
          return false;
        }
      }
      return true;
    }

    // Optimistically show local preview immediately
    _avatarUrl = localFilePath;
    notifyListeners();

    if (client == null || !isAuthenticated || _user == null) {
      return true;
    }

    try {
      final file = File(localFilePath);
      final bytes = await file.readAsBytes();
      final ext = localFilePath.split('.').last.toLowerCase();
      final storagePath =
          '${_user!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('avatars').uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
            ),
          );

      final publicUrl =
          client.storage.from('avatars').getPublicUrl(storagePath);
      _avatarUrl = publicUrl;
      notifyListeners();

      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );
      return true;
    } catch (_) {
      _avatarUrl = prevAvatar;
      _errorMessage = 'Failed to upload profile photo.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    _user = null;
    _isGuest = false;
    _errorMessage = null;
    _resetProfileDefaults();
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}