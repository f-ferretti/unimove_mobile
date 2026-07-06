import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/home_screen.dart';

final myRidesProvider = FutureProvider<List<Ride>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('rides/my');
  if (response.statusCode == 200 && response.data != null) {
    final list = response.data as List<dynamic>;
    return list.map((e) => Ride.fromJson(e as Map<String, dynamic>)).toList();
  }
  throw Exception('Impossibile caricare l\'elenco delle tue corse');
});

class MyRidesService {
  final ApiClient _apiClient;
  final Ref _ref;

  MyRidesService(this._apiClient, this._ref);

  Future<void> startRide(String rideId) async {
    try {
      final response = await _apiClient.dio.put('rides/$rideId/start');
      if (response.statusCode == 200) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
      } else {
        throw Exception('Errore durante l\'avvio della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile avviare la corsa';
      throw Exception(msg);
    }
  }

  Future<void> completeRide(String rideId) async {
    try {
      final response = await _apiClient.dio.put('rides/$rideId/complete');
      if (response.statusCode == 200) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
        _ref.invalidate(archivedRidesProvider);
      } else {
        throw Exception('Errore durante il completamento della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile completare la corsa';
      throw Exception(msg);
    }
  }

  Future<void> deleteRide(String rideId) async {
    try {
      final response = await _apiClient.dio.delete('rides/$rideId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
      } else {
        throw Exception('Errore durante l\'eliminazione della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile eliminare la corsa';
      throw Exception(msg);
    }
  }
}

final myRidesServiceProvider = Provider<MyRidesService>((ref) {
  return MyRidesService(ref.watch(apiClientProvider), ref);
});
