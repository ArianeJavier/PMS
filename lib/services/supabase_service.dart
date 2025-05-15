import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client; // Changed from _client to client (public)
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
    try {
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'email': email,
          'full_name': '${userData['first_name']} ${userData['last_name']}',
        },
      );

      if (authResponse.user == null) {
        throw Exception("User registration failed");
      }

      final patientNumber = await _generatePatientNumber();
      await client.from('patient').insert({
        'patient_id': authResponse.user!.id,
        'patient_number': patientNumber,
        'email': email,
        ...userData,
      });

      return authResponse;
    } catch (e) {
      rethrow;
    }
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
      await client.auth.signOut();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email)
      .timeout(_timeoutDuration);
  }

  Future<String> _generatePatientNumber() async {
    final currentYear = DateTime.now().year.toString();
    final response = await client
        .from('patient')
        .select('patient_number')
        .like('patient_number', '$currentYear-%')
        .order('patient_number', ascending: false)
        .limit(1)
        .timeout(_timeoutDuration);
    
    if (response.isEmpty) return '$currentYear-0001';
    
    final lastNumber = response[0]['patient_number'] as String;
    final sequence = int.parse(lastNumber.split('-')[1]) + 1;
    return '$currentYear-${sequence.toString().padLeft(4, '0')}';
  }

  Future<Map<String, dynamic>> registerPatient(Map<String, dynamic> patientData) async {
    try {
      final patientNumber = await _generatePatientNumber();
      final response = await client
          .from('patient')
          .insert({
            ...patientData,
            'patient_number': patientNumber,
          })
          .select()
          .single()
          .timeout(_timeoutDuration);
      return response;
    } catch (e) {
      throw Exception('Failed to register patient: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getPatientProfile(String patientId) async {
    try {
      final response = await client.from('patient')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle()
        .timeout(_timeoutDuration);
      return response;
    } catch (e) {
      throw Exception('Failed to fetch patient profile: ${e.toString()}');
    }
  }

  Future<void> updatePatientProfile(String patientId, Map<String, dynamic> data) async {
    try {
      await client.from('patient')
        .update(data)
        .eq('patient_id', patientId)
        .timeout(_timeoutDuration);
    } catch (e) {
      throw Exception('Failed to update patient profile: ${e.toString()}');
    }
  }

  Future<void> addMedicalHistory(Map<String, dynamic> data) async {
    try {
      await client.from('medical_history')
        .insert(data)
        .timeout(_timeoutDuration);
    } catch (e) {
      throw Exception('Failed to add medical history: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMedicalHistory(String patientId) async {
    try {
      final response = await client.from('medical_history')
        .select()
        .eq('patient_id', patientId)
        .order('date', ascending: false)
        .timeout(_timeoutDuration);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get medical history: ${e.toString()}');
    }
  }

  Future<void> createAppointment(Map<String, dynamic> data) async {
    try {
      await client.from('appointment')
        .insert(data)
        .timeout(_timeoutDuration);
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getAppointments(String patientId) async {
    try {
      final response = await client.from('appointment')
        .select()
        .eq('patient_id', patientId)
        .order('appointment_date', ascending: true)
        .timeout(_timeoutDuration);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get appointments: ${e.toString()}');
    }
  }
}