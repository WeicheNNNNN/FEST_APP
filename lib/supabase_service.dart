import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  Future<String?> getOrganizerPassword() async {
    final response =
        await client
            .from('password')
            .select('value')
            .eq('key', 'organizer_password')
            .maybeSingle();

    if (response == null) {
      return null;
    }

    return response['value'] as String?;
  }

  Future<List<Map<String, dynamic>>> getFestivals() async {
    final response = await client
        .from('festivals')
        .select('id, name, start, end, stages, image, city, isPaid, map')
        .order('start', ascending: true);
    return (response as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<void> addFestival(Map<String, dynamic> festival) async {
    await client.from('festivals').insert(festival);
  }

  Future<void> updateFestival(
    String id,
    Map<String, dynamic> updatedFestival,
  ) async {
    await client.from('festivals').update(updatedFestival).eq('id', id);
  }

  Future<void> deleteFestival(String id) async {
    await client.from('festivals').delete().eq('id', id);
  }
}
