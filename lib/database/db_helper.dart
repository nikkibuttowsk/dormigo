import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef JsonMap = Map<String, dynamic>;

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Ensures user has an active session (uses anonymous sign-in for instant onboarding)
  Future<String> ensureSession() async {
    if (_client.auth.currentUser == null) {
      await _client.auth.signInAnonymously();
    }
    final uid = _client.auth.currentUser!.id;

    // Ensure profile row exists
    await _client.from('user_profiles').upsert(
      {'id': uid},
      onConflict: 'id',
      ignoreDuplicates: true,
    );

    return uid;
  }

  // --- PANTRY CRUD ---
  Future<List<JsonMap>> fetchPantryItems() async {
    final uid = await ensureSession();
    final response = await _client
        .from('pantry_items')
        .select()
        .eq('user_id', uid)
        .eq('status', 'active')
        .order('expiry_date', ascending: true, nullsFirst: false);
    return List<JsonMap>.from(response);
  }

  Future<JsonMap> insertPantryItem(JsonMap data) async {
    final uid = await ensureSession();
    final payload = <String, dynamic>{
      ...data,
      'user_id': uid,
      'status': 'active',
    };
    final response = await _client
        .from('pantry_items')
        .insert(payload)
        .select()
        .single();
    return JsonMap.from(response);
  }

  Future<void> updateItemStatus(String itemId, String status) async {
    // status: 'consumed' (saved!) or 'discarded' (wasted)
    await _client
        .from('pantry_items')
        .update({'status': status})
        .eq('id', itemId);
  }

  // --- EQUIPMENT (Screen 08) ---
  Future<List<String>> fetchUserEquipment() async {
    final uid = await ensureSession();
    final response = await _client
        .from('user_profiles')
        .select('equipment')
        .eq('id', uid)
        .single();
    return List<String>.from(response['equipment'] ?? ['Rice Cooker', 'Kettle']);
  }

  Future<void> saveUserEquipment(List<String> equipment) async {
    final uid = await ensureSession();
    await _client.from('user_profiles').upsert({
      'id': uid,
      'equipment': equipment,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}