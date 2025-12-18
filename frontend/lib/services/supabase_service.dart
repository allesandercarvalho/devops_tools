import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null || (_isDevMode && _hasDevSession);
  bool _hasDevSession = false;

  // Mock auth for development
  bool get _isDevMode => true;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseService() {
    _init();
  }

  Future<void> _init() async {
    if (_isDevMode) {
      final prefs = await SharedPreferences.getInstance();
      _hasDevSession = prefs.getBool('dev_session') ?? false;
    }
    _isInitialized = true;
    notifyListeners();
  }

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    if (_isDevMode) {
      _hasDevSession = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_session', true);
      
      notifyListeners();
      return AuthResponse(
        session: Session(
          accessToken: 'mock-token',
          tokenType: 'bearer',
          user: User(
            id: 'dev-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
        user: User(
          id: 'dev-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    if (_isDevMode) {
      return signIn(email, password);
    }

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (_isDevMode) {
      _hasDevSession = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dev_session', false);
      
      notifyListeners();
      return;
    }
    await _client.auth.signOut();
    notifyListeners();
  }

  // Get tool configurations
  Future<List<Map<String, dynamic>>> getToolConfigs() async {
    if (_isDevMode) {
      try {
        final response = await http.get(Uri.parse('http://localhost:3002/api/configs'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } catch (e) {
        debugPrint('Error fetching configs from backend: $e');
        return [];
      }
    }

    final response = await _client
        .from('tool_configs')
        .select()
        .match({'user_id': currentUser!.id});
    return List<Map<String, dynamic>>.from(response);
  }

  // Create tool configuration
  Future<Map<String, dynamic>> createToolConfig(Map<String, dynamic> config) async {
    if (_isDevMode) {
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/configs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      );
      if (response.statusCode == 201) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
      throw Exception('Failed to create config');
    }

    final response = await _client
        .from('tool_configs')
        .insert({
          ...config,
          'user_id': currentUser!.id,
        })
        .select()
        .single();
    return response;
  }

  // Update tool configuration
  Future<Map<String, dynamic>> updateToolConfig(String id, Map<String, dynamic> config) async {
    final response = await _client
        .from('tool_configs')
        .update(config)
        .match({'id': id})
        .select()
        .single();
    return response;
  }

  // Delete tool configuration
  Future<void> deleteToolConfig(String id) async {
    await _client
        .from('tool_configs')
        .delete()
        .match({'id': id});
  }

  // Get command history
  Future<List<Map<String, dynamic>>> getCommandHistory({String? toolType}) async {
    final filters = {'user_id': currentUser!.id};
    if (toolType != null) {
      filters['tool_type'] = toolType;
    }
    
    final response = await _client
        .from('command_history')
        .select()
        .match(filters)
        .order('executed_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Subscribe to sync events
  RealtimeChannel subscribeSyncEvents(Function(Map<String, dynamic>) onEvent) {
    return _client
        .channel('sync_events')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sync_events',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser!.id,
          ),
          callback: (payload) {
            onEvent(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    if (_isDevMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final prefsJson = prefs.getString('user_preferences');
        if (prefsJson != null) {
          return Map<String, dynamic>.from(json.decode(prefsJson));
        }
        return null;
      } catch (e) {
        debugPrint('Error loading preferences: $e');
        return null;
      }
    }

    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .match({'user_id': currentUser!.id})
          .maybeSingle();
      return response?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      return null;
    }
  }

  // Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    if (_isDevMode) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getString('user_preferences');
        final Map<String, dynamic> currentPrefs = existing != null
            ? Map<String, dynamic>.from(json.decode(existing))
            : {};
        currentPrefs.addAll(preferences);
        await prefs.setString('user_preferences', json.encode(currentPrefs));
      } catch (e) {
        debugPrint('Error saving preferences: $e');
      }
      return;
    }

    try {
      final existing = await getUserPreferences();
      final Map<String, dynamic> currentPrefs = existing ?? {};
      currentPrefs.addAll(preferences);

      await _client
          .from('user_preferences')
          .upsert({
            'user_id': currentUser!.id,
            'preferences': currentPrefs,
          });
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      rethrow;
    }
  }
}
