import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Returns the current authenticated (non-anonymous) user's ID, or null.
  String? get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null || user.isAnonymous) return null;
    return user.id;
  }

  /// Ensures a signed-in (non-anonymous) user and user_profiles row exist.
  Future<String> requireAuthenticatedUserId() async {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('Authenticated user required for Supabase operations.');
    }

    await _client.from('user_profiles').upsert(
      {'id': uid},
      onConflict: 'id',
      ignoreDuplicates: true,
    );

    return uid;
  }

  bool _isMissingImageColumnError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('image_url') &&
        (msg.contains('column') || msg.contains('schema cache'));
  }

  // --- PANTRY CRUD ---
  Future<List<JsonMap>> fetchPantryItems() async {
    final uid = await requireAuthenticatedUserId();
    final response = await _client
        .from('pantry_items')
        .select()
        .eq('user_id', uid)
        .eq('status', 'active')
        .order('expiry_date', ascending: true, nullsFirst: false);
    return List<JsonMap>.from(response);
  }

  Future<JsonMap> insertPantryItem(JsonMap data) async {
    final uid = await requireAuthenticatedUserId();
    final payload = <String, dynamic>{
      ...data,
      'user_id': uid,
      'status': 'active',
    };
    try {
      final response = await _client
          .from('pantry_items')
          .insert(payload)
          .select()
          .single();
      return JsonMap.from(response);
    } catch (e) {
      if (payload.containsKey('image_url') && _isMissingImageColumnError(e)) {
        final fallback = Map<String, dynamic>.from(payload)
          ..remove('image_url');
        final response = await _client
            .from('pantry_items')
            .insert(fallback)
            .select()
            .single();
        return JsonMap.from(response);
      }
      rethrow;
    }
  }

  Future<JsonMap> updatePantryItem(String itemId, JsonMap data) async {
    final uid = await requireAuthenticatedUserId();
    try {
      final response = await _client
          .from('pantry_items')
          .update(data)
          .eq('id', itemId)
          .eq('user_id', uid)
          .select()
          .single();
      return JsonMap.from(response);
    } catch (e) {
      if (data.containsKey('image_url') && _isMissingImageColumnError(e)) {
        final fallback = Map<String, dynamic>.from(data)..remove('image_url');
        final response = await _client
            .from('pantry_items')
            .update(fallback)
            .eq('id', itemId)
            .eq('user_id', uid)
            .select()
            .single();
        return JsonMap.from(response);
      }
      rethrow;
    }
  }

  Future<void> updateItemStatus(String itemId, String status) async {
    final uid = await requireAuthenticatedUserId();
    await _client
        .from('pantry_items')
        .update({'status': status})
        .eq('id', itemId)
        .eq('user_id', uid);
  }

  Future<void> deletePantryItem(String itemId) async {
    final uid = await requireAuthenticatedUserId();
    await _client
        .from('pantry_items')
        .delete()
        .eq('id', itemId)
        .eq('user_id', uid);
  }

  // --- EQUIPMENT ---
  Future<List<String>> fetchUserEquipment() async {
    final uid = await requireAuthenticatedUserId();
    final response = await _client
        .from('user_profiles')
        .select('equipment')
        .eq('id', uid)
        .maybeSingle();
    return List<String>.from(
      response?['equipment'] ?? ['Rice Cooker', 'Kettle'],
    );
  }

  Future<void> saveUserEquipment(List<String> equipment) async {
    final uid = await requireAuthenticatedUserId();
    await _client.from('user_profiles').upsert({
      'id': uid,
      'equipment': equipment,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}