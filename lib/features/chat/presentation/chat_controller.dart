import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';
import '../../rides/presentation/my_rides_controller.dart';
import '../../rides/presentation/my_bookings_controller.dart';

class Message {
  final String id;
  final String senderUsername;
  final String senderFullName;
  final String content;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderUsername,
    required this.senderFullName,
    required this.content,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderUsername: json['senderUsername'] as String? ?? '',
      senderFullName: json['senderFullName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, rideId) async* {
  final apiClient = ref.watch(apiClientProvider);

  Future<List<Message>> fetchMessages() async {
    final response = await apiClient.dio.get('rides/$rideId/messages');
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Errore caricamento messaggi');
  }

  // Emit immediately first
  yield await fetchMessages();

  // Then poll every 3 seconds
  yield* Stream.periodic(const Duration(seconds: 3)).asyncMap((_) => fetchMessages());
});

final activeChatsProvider = FutureProvider<List<Ride>>((ref) async {
  // Watch active driver rides and passenger bookings
  final myRides = await ref.watch(myRidesProvider.future);
  final myBookings = await ref.watch(myBookingsProvider.future);

  final List<Ride> result = [];

  // Add all my driver rides
  result.addAll(myRides);

  // Add rides from my CONFIRMED passenger bookings
  for (final booking in myBookings) {
    if (booking.status == 'CONFIRMED' && booking.ride != null) {
      if (!result.any((r) => r.id == booking.ride!.id)) {
        result.add(booking.ride!);
      }
    }
  }

  // Sort by departure time
  result.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  return result;
});

class ChatService {
  final ApiClient _apiClient;
  final Ref _ref;

  ChatService(this._apiClient, this._ref);

  Future<void> sendMessage(String rideId, String content, {double? latitude, double? longitude}) async {
    try {
      final response = await _apiClient.dio.post(
        'rides/$rideId/messages',
        data: {
          'content': content,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );
      if (response.statusCode == 201) {
        _ref.invalidate(chatMessagesProvider(rideId));
      } else {
        throw Exception('Errore nell\'invio del messaggio');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? e.message ?? 'Impossibile inviare il messaggio';
      throw Exception(msg);
    }
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(apiClientProvider), ref);
});
