import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final ApiClient _apiClient;

  ProfileController(this._apiClient) : super(const AsyncValue.loading());

  Future<UserProfile?> fetchProfile() async {
    if (state.value == null) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _apiClient.dio.get('users/me');
      if (response.statusCode == 200 && response.data != null) {
        final profile = UserProfile.fromJson(response.data as Map<String, dynamic>);
        state = AsyncValue.data(profile);
        return profile;
      }
      throw Exception('Impossibile caricare il profilo');
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<bool> updatePreferences(String travelPreferences) async {
    final currentProfile = state.value;
    if (currentProfile == null) return false;

    try {
      final response = await _apiClient.dio.put(
        'users/me/preferences',
        data: {'travelPreferences': travelPreferences},
      );
      if (response.statusCode == 200) {
        final updatedProfile = currentProfile.copyWith(travelPreferences: travelPreferences);
        state = AsyncValue.data(updatedProfile);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateIban(String iban, String ibanHolder) async {
    final currentProfile = state.value;
    if (currentProfile == null) return false;

    try {
      final response = await _apiClient.dio.put(
        'users/me/iban',
        data: {
          'iban': iban,
          'ibanHolder': ibanHolder,
        },
      );
      if (response.statusCode == 200) {
        final updatedProfile = currentProfile.copyWith(iban: iban, ibanHolder: ibanHolder);
        state = AsyncValue.data(updatedProfile);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileController(apiClient);
});
