import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client;
  static const _timeoutDuration = Duration(seconds: 10);

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    await dotenv.load();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
        // persistSession parameter has been removed - session persistence is now always enabled
      ),
    );

    client = Supabase.instance.client;
  }

  // Auth methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final AuthResponse res = await client.auth.signUp(
      email: email,
      password: password,
      data: userData,
    ).timeout(_timeoutDuration);

    if (res.user != null) {
      try {
        final patientData = {
          'patient_id': res.user!.id,
          'email': email,
          'first_name': userData['first_name'],
          'middle_name': userData['middle_name'],
          'last_name': userData['last_name'],
          'username': userData['username'] ?? email.split('@')[0],
          'sex': userData['sex'],
        };

        await client.from('patient')
          .insert(patientData)
          .timeout(_timeoutDuration);
      } catch (e) {
        await client.auth.signOut(); // Rollback if profile creation fails
        rethrow;
      }
    }

    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    ).timeout(_timeoutDuration);
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut().timeout(const Duration(seconds: 5));
    } catch (e) {
      // Force clear local session if timeout occurs
      await client.auth.signOut(); // clearSession has been renamed to signOut
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email)
      .timeout(_timeoutDuration);
  }

  // Patient methods
  Future<Map<String, dynamic>?> getPatientProfile(String patientId) async {
    final response = await client.from('patient')
      .select()
      .eq('patient_id', patientId)
      .single()
      .timeout(_timeoutDuration);

    return response;
  }

  Future<void> updatePatientProfile(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    await client.from('patient')
      .update(data)
      .eq('patient_id', patientId)
      .timeout(_timeoutDuration);
  }

  // Medical History methods
  Future<void> addMedicalHistory(Map<String, dynamic> data) async {
    await client.from('medical_history')
      .insert(data)
      .timeout(_timeoutDuration);
  }

  Future<List<Map<String, dynamic>>> getMedicalHistory(String patientId) async {
    final response = await client.from('medical_history')
      .select()
      .eq('patient_id', patientId)
      .order('date', ascending: false)
      .timeout(_timeoutDuration);

    return List<Map<String, dynamic>>.from(response);
  }

  // Appointment methods
  Future<void> createAppointment(Map<String, dynamic> data) async {
    await client.from('appointment')
      .insert(data)
      .timeout(_timeoutDuration);
  }

  Future<List<Map<String, dynamic>>> getAppointments(String patientId) async {
    final response = await client.from('appointment')
      .select()
      .eq('patient_id', patientId)
      .order('appointment_date', ascending: true)
      .timeout(_timeoutDuration);

    return List<Map<String, dynamic>>.from(response);
  }
}